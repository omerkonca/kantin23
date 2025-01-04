import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { DashboardLayout } from './layouts/DashboardLayout';
import { UrunlerPage } from './pages/admin/UrunlerPage';
import { SatislarPage } from './pages/admin/SatislarPage';
import { BakiyeYuklePage } from './pages/admin/BakiyeYuklePage';
import { RaporlarPage } from './pages/admin/RaporlarPage';
import { SiparisPage } from './pages/customer/SiparisPage';
import { SiparisGecmisiPage } from './pages/customer/SiparisGecmisiPage';
import { BakiyePage } from './pages/customer/BakiyePage';
import { UserRole } from './types';

// Test için sabit kullanıcı
const TEST_USER = {
  id: '1',
  email: 'test@example.com',
  name: 'Test Kullanıcı',
  role: 'admin' as UserRole,
  balance: 1000
};

export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<DashboardLayout user={TEST_USER} />}>
          <Route index element={<UrunlerPage />} />
          <Route path="urunler" element={<UrunlerPage />} />
          <Route path="satislar" element={<SatislarPage />} />
          <Route path="bakiye-yukle" element={<BakiyeYuklePage />} />
          <Route path="raporlar" element={<RaporlarPage />} />
          <Route path="siparis" element={<SiparisPage />} />
          <Route path="gecmis" element={<SiparisGecmisiPage />} />
          <Route path="bakiye" element={<BakiyePage />} />
        </Route>
      </Routes>
    </Router>
  );
}