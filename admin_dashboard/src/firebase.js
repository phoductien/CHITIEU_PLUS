import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyDtZejb2lI_17GlMNjz0nRp5GCqxoKuwwI",
  authDomain: "chitieuplus-app.firebaseapp.com",
  projectId: "chitieuplus-app",
  storageBucket: "chitieuplus-app.firebasestorage.app",
  messagingSenderId: "971401377167",
  appId: "1:971401377167:web:3fdda45472a9055962c7fa",
  measurementId: "G-QG3QNCXFZ6"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
