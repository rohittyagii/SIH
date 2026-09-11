"use client";

import { useAuth } from "@/lib/auth";
import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Button } from "@/components/ui/button";

export default function SettingsPage() {
  const { user } = useAuth();
  const [language, setLanguage] = useState("en");
  const [isSaved, setIsSaved] = useState(false);

  useEffect(() => {
    // Load language preference from localStorage if available
    const savedLanguage = localStorage.getItem("welfare_language");
    if (savedLanguage) {
      // eslint-disable-next-line
      setLanguage(savedLanguage);
    }
  }, []);

  const handleSave = () => {
    localStorage.setItem("welfare_language", language);
    
    // Clear existing google translate cookies to avoid conflicts
    document.cookie = "googtrans=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie = `googtrans=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=${window.location.hostname};`;
    
    if (language !== "en") {
      // Set new google translate cookie
      document.cookie = `googtrans=/en/${language}; path=/;`;
    }
    
    setIsSaved(true);
    
    // Reload to apply translation
    setTimeout(() => {
      window.location.reload();
    }, 400);
  };

  if (!user) return null;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground mt-2">Manage your account settings and preferences.</p>
      </div>

      <div className="grid gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Account Information</CardTitle>
            <CardDescription>Your personal and organizational details.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 bg-muted/30 p-4 rounded-lg border">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Full Name</p>
                <p className="font-medium mt-1">{user.full_name}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground">Username</p>
                <p className="font-medium mt-1">{user.username}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground">Role</p>
                <p className="font-medium mt-1">{user.role?.replace("_", " ")}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground">Unit</p>
                <p className="font-medium mt-1">{user.unit}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground">Service ID</p>
                <p className="font-medium mt-1">{user.service_id}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Preferences</CardTitle>
            <CardDescription>Manage your dashboard preferences.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="space-y-3 max-w-sm">
              <label className="text-sm font-medium leading-none">
                Interface Language
              </label>
              <Select value={language} onValueChange={(val) => val && setLanguage(val)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select Language" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="en">English</SelectItem>
                  <SelectItem value="hi">Hindi (हिन्दी)</SelectItem>
                  <SelectItem value="pa">Punjabi (ਪੰਜਾਬੀ)</SelectItem>
                  <SelectItem value="bn">Bengali (বাংলা)</SelectItem>
                  <SelectItem value="te">Telugu (తెలుగు)</SelectItem>
                  <SelectItem value="mr">Marathi (मराठी)</SelectItem>
                  <SelectItem value="ta">Tamil (தமிழ்)</SelectItem>
                </SelectContent>
              </Select>
              <p className="text-[13px] text-muted-foreground">
                Select your preferred language for the dashboard interface.
              </p>
            </div>
            
            <div className="pt-4 flex items-center gap-4">
              <Button onClick={handleSave}>
                Save Preferences
              </Button>
              {isSaved && <span className="text-sm text-green-600 dark:text-green-500 font-medium">Settings saved!</span>}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
