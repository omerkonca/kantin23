import React from 'react';
import { Coffee } from 'lucide-react';

export function Logo() {
  return (
    <div className="flex items-center space-x-2">
      <Coffee className="h-8 w-8 text-indigo-600" />
      <span className="text-xl font-bold text-gray-900">Kantin 23</span>
    </div>
  );
}