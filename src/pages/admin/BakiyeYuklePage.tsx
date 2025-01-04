import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { User } from '../../types';
import { Search } from 'lucide-react';

export function BakiyeYuklePage() {
  const [searchTerm, setSearchTerm] = useState('');
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(false);
  const [users, setUsers] = useState<User[]>([]);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  async function searchUsers(term: string) {
    if (term.length < 3) return;

    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .ilike('name', `%${term}%`)
        .eq('role', 'customer');

      if (error) throw error;
      setUsers(data || []);
    } catch (error) {
      console.error('Kullanıcı araması sırasında hata:', error);
    }
  }

  async function bakiyeYukle() {
    if (!selectedUser || !amount) return;
    setLoading(true);

    try {
      // Ödeme kaydı oluştur
      const { error: paymentError } = await supabase
        .from('payments')
        .insert([
          {
            user_id: selectedUser.id,
            amount: parseFloat(amount)
          }
        ]);

      if (paymentError) throw paymentError;

      // Kullanıcı bakiyesini güncelle
      const { error: updateError } = await supabase
        .from('profiles')
        .update({
          balance: selectedUser.balance + parseFloat(amount)
        })
        .eq('id', selectedUser.id);

      if (updateError) throw updateError;

      setAmount('');
      setSelectedUser(null);
      setSearchTerm('');
      setUsers([]);
      alert('Bakiye yükleme işlemi başarılı!');
    } catch (error) {
      console.error('Bakiye yükleme sırasında hata:', error);
      alert('Bakiye yükleme işlemi başarısız oldu.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">Bakiye Yükleme</h2>

      <div className="bg-white rounded-lg shadow-sm p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Müşteri Ara</label>
          <div className="mt-1 relative">
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                searchUsers(e.target.value);
              }}
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
              placeholder="Müşteri adı..."
            />
            <Search className="absolute right-3 top-2.5 text-gray-400" size={20} />
          </div>

          {users.length > 0 && !selectedUser && (
            <div className="mt-2 border rounded-md divide-y">
              {users.map(user => (
                <button
                  key={user.id}
                  onClick={() => setSelectedUser(user)}
                  className="w-full px-4 py-2 text-left hover:bg-gray-50"
                >
                  {user.name}
                </button>
              ))}
            </div>
          )}
        </div>

        {selectedUser && (
          <>
            <div className="p-4 bg-gray-50 rounded-md">
              <p className="font-medium">{selectedUser.name}</p>
              <p className="text-sm text-gray-500">Mevcut Bakiye: ₺{selectedUser.balance.toFixed(2)}</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Yüklenecek Tutar (₺)</label>
              <input
                type="number"
                step="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
              />
            </div>

            <button
              onClick={bakiyeYukle}
              disabled={loading || !amount}
              className="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              {loading ? 'İşleniyor...' : 'Bakiye Yükle'}
            </button>
          </>
        )}
      </div>
    </div>
  );
}