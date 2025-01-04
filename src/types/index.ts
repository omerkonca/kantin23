export type UserRole = 'admin' | 'customer';

export interface User {
  id: string;
  email: string;
  role: UserRole;
  name: string;
  balance?: number;
}

export interface Product {
  id: string;
  name: string;
  price: number;
  stock: number;
  created_by: string;
  created_at: string;
}

export interface Sale {
  id: string;
  user_id: string;
  product_id: string;
  quantity: number;
  total_price: number;
  created_at: string;
  products?: {
    name: string;
    price: number;
  };
  profiles?: {
    name: string;
  };
}

export interface Payment {
  id: string;
  user_id: string;
  amount: number;
  created_at: string;
}