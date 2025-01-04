import React from 'react';
import { NavLink } from 'react-router-dom';
import { 
  ShoppingBag, 
  Package, 
  CreditCard, 
  History,
  BarChart3
} from 'lucide-react';
import { User } from '../../types';

interface SidebarProps {
  user: User;
}

export function Sidebar({ user }: SidebarProps) {
  const isAdmin = user.role === 'admin';

  return (
    <aside className="w-64 bg-white shadow-sm min-h-screen">
      <nav className="mt-5 px-2">
        {isAdmin ? (
          <div className="space-y-1">
            <NavItem icon={Package} to="/urunler" text="Ürünler" />
            <NavItem icon={ShoppingBag} to="/satislar" text="Satışlar" />
            <NavItem icon={CreditCard} to="/bakiye-yukle" text="Bakiye Yükle" />
            <NavItem icon={BarChart3} to="/raporlar" text="Raporlar" />
          </div>
        ) : (
          <div className="space-y-1">
            <NavItem icon={ShoppingBag} to="/siparis" text="Sipariş Ver" />
            <NavItem icon={History} to="/gecmis" text="Sipariş Geçmişi" />
            <NavItem icon={CreditCard} to="/bakiye" text="Bakiyem" />
          </div>
        )}
      </nav>
    </aside>
  );
}

interface NavItemProps {
  icon: React.ElementType;
  to: string;
  text: string;
}

function NavItem({ icon: Icon, to, text }: NavItemProps) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        `flex items-center px-4 py-2 text-sm font-medium rounded-md ${
          isActive
            ? 'bg-indigo-50 text-indigo-700'
            : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
        }`
      }
    >
      <Icon className="mr-3 h-5 w-5" />
      {text}
    </NavLink>
  );
}