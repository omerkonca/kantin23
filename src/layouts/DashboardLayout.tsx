import React from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from '../components/dashboard/Sidebar';
import { Header } from '../components/dashboard/Header';
import { User } from '../types';

interface DashboardLayoutProps {
  user: User;
}

export function DashboardLayout({ user }: DashboardLayoutProps) {
  return (
    <div className="min-h-screen bg-gray-100">
      <Header user={user} />
      <div className="flex flex-col md:flex-row">
        <Sidebar user={user} />
        <main className="flex-1 p-4 md:p-6 overflow-x-hidden">
          <div className="max-w-7xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}