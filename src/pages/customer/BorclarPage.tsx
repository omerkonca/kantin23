import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { Credit } from '../../types';
import { VeresiyeOdemeForm } from '../../components/customer/VeresiyeOdemeForm';
import { formatCurrency } from '../../utils/currency';
import { formatDate } from '../../utils/date';
import { CreditCard } from 'lucide-react';

export function BorclarPage() {
  const [credits, setCredits] = useState<Credit[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    if (user) {
      fetchCredits();
    }
  }, [user]);

  async function fetchCredits() {
    try {
      const { data, error } = await supabase
        .from('credits')
        .select('*')
        .eq('user_id', user?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setCredits(data || []);
    } catch (error) {
      console.error('Borçlar yüklenirken hata:', error);
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
      <div className="flex items-center space-x-3">
        <CreditCard className="h-8 w-8 text-indigo-600" />
        <h2 className="text-2xl font-bold text-gray-900">Borçlarım</h2>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {credits.map((credit) => (
          <div key={credit.id} className="bg-white rounded-lg shadow-sm p-6">
            <div className="space-y-4">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm text-gray-500">
                    Oluşturulma: {formatDate(credit.created_at)}
                  </p>
                  <p className="text-sm text-gray-500">
                    Son Ödeme: {formatDate(credit.due_date)}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-lg font-medium text-gray-900">
                    {formatCurrency(credit.amount)}
                  </p>
                  <p className="text-sm text-green-600">
                    Ödenen: {formatCurrency(credit.paid_amount)}
                  </p>
                </div>
              </div>

              {credit.amount > credit.paid_amount && (
                <VeresiyeOdemeForm credit={credit} onSuccess={fetchCredits} />
              )}
            </div>
          </div>
        ))}

        {credits.length === 0 && (
          <div className="col-span-2 bg-white rounded-lg shadow-sm p-6 text-center text-gray-500">
            Henüz borç kaydınız bulunmuyor.
          </div>
        )}
      </div>
    </div>
  );
}