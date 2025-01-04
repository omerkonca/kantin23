import React from 'react';
import { Product } from '../../types';
import { Plus, Minus } from 'lucide-react';

interface UrunCardProps {
  urun: Product;
  miktar: number;
  onEkle: () => void;
  onCikar: () => void;
}

export function UrunCard({ urun, miktar, onEkle, onCikar }: UrunCardProps) {
  return (
    <div className="bg-white rounded-lg shadow-sm p-4">
      <h3 className="text-lg font-medium text-gray-900">{urun.name}</h3>
      <p className="text-gray-500">Stok: {urun.stock}</p>
      <p className="text-lg font-semibold text-indigo-600 mt-2">₺{urun.price.toFixed(2)}</p>
      
      <div className="mt-4 flex items-center justify-between">
        {miktar > 0 ? (
          <div className="flex items-center space-x-2">
            <button
              onClick={onCikar}
              className="p-1 rounded-full bg-gray-100 hover:bg-gray-200"
            >
              <Minus size={16} />
            </button>
            <span className="font-medium">{miktar}</span>
            <button
              onClick={onEkle}
              className="p-1 rounded-full bg-gray-100 hover:bg-gray-200"
              disabled={miktar >= urun.stock}
            >
              <Plus size={16} />
            </button>
          </div>
        ) : (
          <button
            onClick={onEkle}
            className="px-3 py-1 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
            disabled={urun.stock === 0}
          >
            Sepete Ekle
          </button>
        )}
      </div>
    </div>
  );
}