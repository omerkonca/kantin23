import React from 'react';
import { Coffee } from 'lucide-react';

export function Logo() {
  return (
    <div className="flex items-center space-x-2">
      <div className="relative">
        <Coffee className="h-8 w-8 text-indigo-600" />
        <div className="absolute top-2 right-1.5 space-y-0.5">
          <div className="w-2 h-0.5 bg-indigo-600 animate-wave" />
          <div className="w-2 h-0.5 bg-indigo-600 animate-wave-delay" />
          <div className="w-2 h-0.5 bg-indigo-600 animate-wave-delay-2" />
        </div>
      </div>
      <span className="text-xl font-bold text-gray-900">Kantin23</span>
    </div>
  );
}