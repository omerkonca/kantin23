import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { Payment } from '../../types';

export function BakiyePage() {
  const [balance, setBalance] = useState<number>(0);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    if (user) {
      fetchBakiyeVeOdemeler();
    }
  }, [user]);

  async function fetchBakiyeVeOdemeler() {
    try {
      // Bakiye bilgisini al
      const { data: profile } = await supabase
        .from('profiles')
        .select('balance')
        .eq('id', user?.id)
        .single();

      if (profile) {
        setBalance(profile.balance);
      }

      // Ödeme geçmişini al
      const { data: paymentsData } = await supabase
        .from('payments')
        .select('*')
        .eq('user_id', user?.id)
        .order('created_at', { ascending: false });

      if (paymentsData) {
        setPayments(paymentsData);
      }
    } catch (error) {
      console.error('Bakiye bilgisi alınırken hata:', error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm p-6">
        <h2 className="text-2xl font-bold text-gray-900">Bakiye Bilgisi</h2>
        <p className="mt-2 text-4xl font-bold text-indigo-600">₺{balance.toFixed(2)}</p>
      </div>

      <div className="bg-white rounded-lg shadow-sm p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Bakiye Yükleme Geçmişi</h3>
        
        <div className="space-y-4">
          {payments.map(payment => (
            <div
              key={payment.id}
              className="flex justify-between items-center border-b pb-4"
            >
              <div>
                <p className="text-sm text-gray-500">
                  {new Date(payment.created_at).toLocaleDateString('tr-TR')}
                </p>
                <p className="font-medium text-green-600">+₺{payment.amount.toFixed(2)}</p>
              </div>
            </div>
          ))}
          
          {payments.length === 0 && (
            <p className="text-gray-500 text-center">Henüz bakiye yükleme işlemi yapılmamış.</p>
          )}
        </div>
      </div>
    </div>
  );
}