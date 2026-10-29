// Emulator tests for ../firestore.rules (cart, favorites, orders).
// Mirrors OrderRemoteDataSource.placeOrder from the Flutter app.
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where,
  getDocs, runTransaction, serverTimestamp,
} from 'firebase/firestore';

const RULES = new URL('../firestore.rules', import.meta.url);

const env = await initializeTestEnvironment({
  projectId: 'demo-shop-rules',
  firestore: { rules: readFileSync(RULES, 'utf8'), host: '127.0.0.1', port: 8085 },
});

const alice = () => env.authenticatedContext('alice', { email: 'alice@example.com' }).firestore();
const bob = () => env.authenticatedContext('bob', { email: 'bob@example.com' }).firestore();
const admin = () => env.authenticatedContext('admin1', { email: 'admin@example.com' }).firestore();

function product(name, price, stock, extra = {}) {
  return { name, description: '', price, imageUrl: '', category: 'Audio', stock, isAvailable: true, ...extra };
}

async function seed(products) {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/admin1'), { name: 'Admin', email: 'admin@example.com', phone: '', address: '', role: 'admin' });
    await setDoc(doc(db, 'users/alice'), { name: 'Alice', email: 'alice@example.com', phone: '', address: '', role: 'customer' });
    for (const [id, data] of Object.entries(products)) {
      await setDoc(doc(db, `products/${id}`), data);
      await setDoc(doc(db, `users/alice/cart/${id}`), { productId: id, quantity: 1 });
    }
  });
}

const base = {
  customerName: 'Alice', customerEmail: 'alice@example.com',
  shippingAddress: '12 Main Street, Cairo', phone: '+20 100 000 0000',
  paymentMethod: 'cash_on_delivery', status: 'pending',
};

/// Same steps as the app. `tamper` can change what gets written.
function placeOrder(db, uid, cart, tamper = {}) {
  const orderRef = doc(collection(db, 'orders'));
  return runTransaction(db, async (tx) => {
    const snaps = [];
    for (const [id] of cart) snaps.push(await tx.get(doc(db, `products/${id}`)));
    const items = {};
    let total = 0;
    cart.forEach(([id, qty], i) => {
      const p = snaps[i].data();
      items[id] = { name: p.name, price: p.price, quantity: qty };
      total += p.price * qty;
    });
    total = Math.round(total * 100) / 100;
    if (tamper.items) tamper.items(items);
    cart.forEach(([id, qty], i) => {
      if (tamper.skipStock === id) return;
      const delta = tamper.stockDelta?.[id] ?? qty;
      tx.update(doc(db, `products/${id}`), { stock: snaps[i].data().stock - delta, lastOrderId: orderRef.id });
    });
    if (!tamper.skipOrder) {
      tx.set(orderRef, {
        ...base, userId: uid, items, totalPrice: tamper.total ?? total,
        createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
        ...(tamper.fields ?? {}),
      });
    }
    for (const [id] of cart) tx.delete(doc(db, `users/${uid}/cart/${id}`));
  }).then(() => orderRef.id);
}

let passed = 0, failed = 0;
async function t(name, fn) {
  try { await fn(); passed++; console.log(`  ok   ${name}`); }
  catch (e) { failed++; console.log(`  FAIL ${name}\n       ${e?.message ?? e}`); }
}

console.log('Orders');
await t('valid order succeeds, reserves stock and empties cart', async () => {
  await seed({ a: product('Amp', 20, 5), b: product('Cable', 7.5, 3) });
  const db = alice();
  const id = await assertSucceeds(placeOrder(db, 'alice', [['a', 2], ['b', 1]]));
  const a = (await getDoc(doc(db, 'products/a'))).data();
  const b = (await getDoc(doc(db, 'products/b'))).data();
  if (a.stock !== 3 || b.stock !== 2) throw new Error(`stock ${a.stock}/${b.stock}`);
  const order = (await getDoc(doc(db, `orders/${id}`))).data();
  if (order.totalPrice !== 47.5) throw new Error(`total ${order.totalPrice}`);
  const cart = await getDocs(collection(db, 'users/alice/cart'));
  if (!cart.empty) throw new Error('cart not empty');
});
await t('float prices with rounding (3 x 0.1 + 1 x 19.99)', async () => {
  await seed({ a: product('Pin', 0.1, 50), b: product('Bag', 19.99, 5) });
  await assertSucceeds(placeOrder(alice(), 'alice', [['a', 3], ['b', 1]]));
});
await t('lower total is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 2]], { total: 1 }));
});
await t('lower item price is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 2]], { items: (i) => { i.a.price = 1; }, total: 2 }));
});
await t('renamed item is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 1]], { items: (i) => { i.a.name = 'Free'; } }));
});
await t('reserving less stock than ordered is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 2]], { stockDelta: { a: 1 } }));
});
await t('order without stock reservation is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 2]], { skipStock: 'a' }));
});
await t('stock reservation without an order is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 2]], { skipOrder: true }));
});
await t('ordering more than the stock is denied', async () => {
  await seed({ a: product('Amp', 20, 1) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 2]]));
});
await t('unavailable product is denied', async () => {
  await seed({ a: product('Amp', 20, 5, { isAvailable: false }) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 1]]));
});
await t('order for another user is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 1]], { fields: { userId: 'bob' } }));
});
await t('non-pending status is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 1]], { fields: { status: 'delivered' } }));
});
await t('replaying an old order id to cut stock is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  const db = alice();
  const id = await placeOrder(db, 'alice', [['a', 1]]);
  await assertFails(updateDoc(doc(db, 'products/a'), { stock: 3, lastOrderId: id }));
});
for (const n of [1, 3, 5, 8]) {
  await t(`${n} different products in one order succeed`, async () => {
    const ps = {};
    for (let i = 0; i < n; i++) ps[`p${i}`] = product(`P${i}`, 1.25 + i, 5);
    await seed(ps);
    await assertSucceeds(placeOrder(alice(), 'alice', Object.keys(ps).map((id) => [id, 2])));
  });
}
await t('negative quantity (to raise stock and cut the total) is denied', async () => {
  await seed({ a: product('Amp', 20, 5), b: product('Cable', 5, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 1], ['b', -2]]));
});
await t('zero quantity is denied', async () => {
  await seed({ a: product('Amp', 20, 5), b: product('Cable', 5, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 1], ['b', 0]]));
});
await t('extra item field is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(placeOrder(alice(), 'alice', [['a', 1]], { items: (i) => { i.a.discount = 5; } }));
});
await t('9 different products are denied', async () => {
  const ps = {};
  for (let i = 0; i < 9; i++) ps[`p${i}`] = product(`P${i}`, 1 + i, 5);
  await seed(ps);
  await assertFails(placeOrder(alice(), 'alice', Object.keys(ps).map((id) => [id, 1])));
});

console.log('Order access');
await t('owner reads, other customer cannot, admin can', async () => {
  await seed({ a: product('Amp', 20, 5) });
  const id = await placeOrder(alice(), 'alice', [['a', 1]]);
  await assertSucceeds(getDoc(doc(alice(), `orders/${id}`)));
  await assertFails(getDoc(doc(bob(), `orders/${id}`)));
  await assertSucceeds(getDoc(doc(admin(), `orders/${id}`)));
});
await t('My Orders query works; unfiltered query is denied', async () => {
  await assertSucceeds(getDocs(query(collection(alice(), 'orders'), where('userId', '==', 'alice'))));
  await assertFails(getDocs(collection(alice(), 'orders')));
});
await t('customers cannot update or delete orders', async () => {
  await seed({ a: product('Amp', 20, 5) });
  const db = alice();
  const id = await placeOrder(db, 'alice', [['a', 1]]);
  await assertFails(updateDoc(doc(db, `orders/${id}`), { status: 'cancelled' }));
  await assertFails(deleteDoc(doc(db, `orders/${id}`)));
});

console.log('Products');
await t('admin can still edit a product that has lastOrderId', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await placeOrder(alice(), 'alice', [['a', 1]]);
  await assertSucceeds(updateDoc(doc(admin(), 'products/a'), { price: 25, stock: 10, updatedAt: serverTimestamp() }));
});
await t('customer cannot change price', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(updateDoc(doc(alice(), 'products/a'), { price: 1 }));
});

console.log('Cart and favorites');
await t('cart write with productId succeeds', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertSucceeds(setDoc(doc(alice(), 'users/alice/cart/a'), { productId: 'a', quantity: 2, updatedAt: serverTimestamp() }, { merge: true }));
});
await t('cart write with wrong productId or quantity is denied', async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(setDoc(doc(alice(), 'users/alice/cart/a'), { productId: 'b', quantity: 2, updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(alice(), 'users/alice/cart/a'), { productId: 'a', quantity: 100, updatedAt: serverTimestamp() }));
});
await t("cannot touch another user's cart", async () => {
  await seed({ a: product('Amp', 20, 5) });
  await assertFails(getDoc(doc(bob(), 'users/alice/cart/a')));
});
await t('favorite add and remove', async () => {
  await seed({ a: product('Amp', 20, 5) });
  const db = alice();
  await assertSucceeds(setDoc(doc(db, 'users/alice/favorites/a'), { productId: 'a', addedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/favorites/a')));
  await assertFails(setDoc(doc(db, 'users/alice/favorites/zzz'), { productId: 'zzz', addedAt: serverTimestamp() }));
});

await env.cleanup();
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
