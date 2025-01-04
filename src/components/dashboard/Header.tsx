import React from 'react';
import { User as UserIcon, LogOut } from 'lucide-react';
import { User } from '../../types';
import { Logo } from '../Logo';
import { supabase } from '../../lib/supabase';

interface HeaderProps {
  user: User;
}

export function Header({ user }: HeaderProps) {
  const handleLogout = async () => {
    await supabase.auth.signOut();
  };

  return (
    <header className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <Logo />
          </div>
          <div className="flex items-center space-x-6">
            <div className="flex items-center space-x-3">
              <UserIcon size={20} className="text-gray-500" />
              <div className="flex flex-col">
                <span className="text-sm font-medium text-gray-700">{user.name}</span>
                {user.role === 'customer' && (
                  <span className="text-sm font-medium text-indigo-600">
                    Bakiye: ₺{user.balance?.toFixed(2)}
                  </span>
                )}
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="flex items-center space-x-2 text-gray-500 hover:text-gray-700"
            >
              <LogOut size={20} />
              <span className="text-sm">Çıkış</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}