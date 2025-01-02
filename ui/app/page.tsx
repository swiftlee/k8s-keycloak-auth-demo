"use client"
import { useState, useEffect } from 'react';

type UserData = {
  nameID: string,
  email: string,
  username: string,
  groups: string[],
  sessionID: string,
}

const App = () => {
  const [userData, setUserData] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(true);

  const API_BASE = 'https://k8s-demo.local';

  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async () => {
    try {
      const response = await fetch(`${API_BASE}/api/user`, {
        credentials: 'include',
      });
      if (response.ok) {
        const data = await response.json();
        setUserData(data);
      }
    } catch (error) {
      console.error('Error checking auth status:', error);
    }
    setLoading(false);
  };

  const handleLogin = () => {
    window.location.href = `${API_BASE}/saml/sso`;
  };

  const handleLogout = async () => {
    try {
      await fetch(`${API_BASE}/api/logout`, {
        method: 'POST',
        credentials: 'include',
      });
      setUserData(null);
    } catch (error) {
      console.error('Error logging out:', error);
    }
  };

  if (loading) {
    return <div className="flex justify-center items-center min-h-screen">Loading...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-100 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-lg shadow-lg overflow-hidden">
        {!userData ? (
          <div className="p-6">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Welcome</h2>
            <button
              onClick={handleLogin}
              className="w-full bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
            >
              Sign in with SAML
            </button>
          </div>
        ) : (
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-semibold text-gray-900">User Information</h2>
              <button
                onClick={handleLogout}
                className="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
              >
                Sign Out
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Name ID</label>
                <p className="mt-1 text-sm text-gray-900">{userData.nameID}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Email</label>
                <p className="mt-1 text-sm text-gray-900">{userData.email}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Username</label>
                <p className="mt-1 text-sm text-gray-900">{userData.username}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Groups</label>
                <ul className="mt-1 space-y-1">
                  {userData.groups.map((group, index) => (
                    <li key={index} className="text-sm text-gray-900">{group}</li>
                  ))}
                </ul>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Session ID</label>
                <p className="mt-1 text-sm text-gray-900">{userData.sessionID}</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default App;