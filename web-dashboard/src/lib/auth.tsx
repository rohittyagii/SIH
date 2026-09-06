"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
import { jwtDecode } from "jwt-decode";

interface User {
  id: number;
  username: string;
  role: string;
  unit: string;
  full_name: string;
  service_id: string;
}

interface JWTPayload {
  sub: string;
  role: string;
  unit: string;
  exp: number;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  role: string | null;
  isAuthenticated: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://sainiksaathi-api.onrender.com";

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(() => {
    if (typeof window !== "undefined") {
      const storedUser = localStorage.getItem("welfare_user");
      return storedUser ? JSON.parse(storedUser) : null;
    }
    return null;
  });
  const [token, setToken] = useState<string | null>(() => {
    if (typeof window !== "undefined") {
      return localStorage.getItem("welfare_token");
    }
    return null;
  });

  const logout = useCallback(() => {
    setUser(null);
    setToken(null);
    localStorage.removeItem("welfare_token");
    localStorage.removeItem("welfare_user");
  }, []);

  useEffect(() => {
    // Restore session from localStorage
    const storedToken = localStorage.getItem("welfare_token");
    const storedUser = localStorage.getItem("welfare_user");
    if (storedToken && storedUser) {
      try {
        const decoded = jwtDecode<JWTPayload>(storedToken);
        if (decoded.exp * 1000 > Date.now()) {
          setToken(storedToken);
          setUser(JSON.parse(storedUser));
        } else {
          logout();
        }
      } catch {
        logout();
      }
    }
  }, [logout]);

  const login = async (username: string, password: string) => {
    // First, get token
    const tokenRes = await fetch(`${API_URL}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ username, password }),
    });

    if (!tokenRes.ok) {
      const err = await tokenRes.json();
      throw new Error(err.detail || "Login failed");
    }

    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;

    // Then get user profile
    const profileRes = await fetch(`${API_URL}/auth/me`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!profileRes.ok) throw new Error("Failed to fetch profile");

    const userData = await profileRes.json();

    setToken(accessToken);
    setUser(userData);
    localStorage.setItem("welfare_token", accessToken);
    localStorage.setItem("welfare_user", JSON.stringify(userData));
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        role: user?.role || null,
        isAuthenticated: !!token,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within AuthProvider");
  return context;
}
