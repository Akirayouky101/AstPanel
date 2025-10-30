'use client';

import { useState } from 'react';

export default function AdminDashboard() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const navigation = [
    { name: 'Dashboard', href: '#', icon: '📊', current: true },
    { name: 'Gestione Utenti', href: '#', icon: '👥', current: false },
    { name: 'Lavorazioni', href: '#', icon: '📋', current: false },
    { name: 'Richieste', href: '#', icon: '💬', current: false },
    { name: 'Calendario', href: '#', icon: '📅', current: false },
    { name: 'Impostazioni', href: '#', icon: '⚙️', current: false },
  ];

  const stats = [
    { name: 'Dipendenti Attivi', value: '12', change: '+2', changeType: 'increase' },
    { name: 'Lavorazioni Aperte', value: '45', change: '+8', changeType: 'increase' },
    { name: 'Richieste Pendenti', value: '7', change: '-3', changeType: 'decrease' },
    { name: 'Completamento Medio', value: '87%', change: '+5%', changeType: 'increase' },
  ];

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Sidebar */}
      <div className={`${sidebarOpen ? 'block' : 'hidden'} fixed inset-0 z-50 lg:block lg:relative lg:inset-auto`}>
        <div className="flex h-full w-64 flex-col bg-white shadow-lg">
          {/* Header */}
          <div className="flex h-16 items-center justify-between px-6 border-b">
            <h1 className="text-xl font-bold text-gray-900">AST Admin</h1>
            <button
              onClick={() => setSidebarOpen(false)}
              className="lg:hidden text-gray-500 hover:text-gray-700"
              aria-label="Chiudi menu"
            >
              ✕
            </button>
          </div>

          {/* Navigation */}
          <nav className="flex-1 px-4 py-6 space-y-2">
            {navigation.map((item) => (
              <a
                key={item.name}
                href={item.href}
                className={`${
                  item.current
                    ? 'bg-red-50 text-red-700 border-red-200'
                    : 'text-gray-700 hover:bg-gray-50'
                } group flex items-center px-3 py-2 text-sm font-medium rounded-lg border transition-colors`}
              >
                <span className="mr-3 text-lg">{item.icon}</span>
                {item.name}
              </a>
            ))}
          </nav>

          {/* User Profile */}
          <div className="border-t p-4">
            <div className="flex items-center">
              <div className="h-8 w-8 rounded-full bg-red-500 flex items-center justify-center">
                <span className="text-sm font-medium text-white">AD</span>
              </div>
              <div className="ml-3">
                <p className="text-sm font-medium text-gray-700">Admin</p>
                <p className="text-xs text-gray-500">Amministratore</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Bar */}
        <header className="bg-white shadow-sm border-b">
          <div className="flex h-16 items-center justify-between px-6">
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden text-gray-500 hover:text-gray-700"
              aria-label="Apri menu"
            >
              ☰
            </button>
            <h2 className="text-lg font-semibold text-gray-900">Dashboard</h2>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-500">
                {new Date().toLocaleDateString('it-IT', { 
                  weekday: 'long', 
                  year: 'numeric', 
                  month: 'long', 
                  day: 'numeric' 
                })}
              </span>
            </div>
          </div>
        </header>

        {/* Dashboard Content */}
        <main className="flex-1 overflow-auto p-6">
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {stats.map((stat) => (
              <div key={stat.name} className="bg-white rounded-lg border p-6 shadow-sm">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                    <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
                  </div>
                  <div className={`text-sm font-medium ${
                    stat.changeType === 'increase' ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {stat.change}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Recent Activity */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Lavorazioni Recenti */}
            <div className="bg-white rounded-lg border p-6 shadow-sm">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Lavorazioni Recenti</h3>
              <div className="space-y-4">
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Manutenzione Impianto A</p>
                    <p className="text-sm text-gray-500">Assegnata a Mario Rossi</p>
                  </div>
                  <span className="px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full">
                    In Corso
                  </span>
                </div>
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Controllo Qualità Lotto B</p>
                    <p className="text-sm text-gray-500">Assegnata a Luca Bianchi</p>
                  </div>
                  <span className="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 rounded-full">
                    Completata
                  </span>
                </div>
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Pulizia Area Produzione</p>
                    <p className="text-sm text-gray-500">Assegnata a Anna Verdi</p>
                  </div>
                  <span className="px-2 py-1 text-xs font-medium bg-blue-100 text-blue-800 rounded-full">
                    Programmata
                  </span>
                </div>
              </div>
            </div>

            {/* Richieste Pendenti */}
            <div className="bg-white rounded-lg border p-6 shadow-sm">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Richieste Pendenti</h3>
              <div className="space-y-4">
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Richiesta Ferie</p>
                    <p className="text-sm text-gray-500">Mario Rossi - 15-20 Nov</p>
                  </div>
                  <div className="flex space-x-2">
                    <button className="px-3 py-1 text-xs font-medium bg-green-100 text-green-800 rounded hover:bg-green-200">
                      Approva
                    </button>
                    <button className="px-3 py-1 text-xs font-medium bg-red-100 text-red-800 rounded hover:bg-red-200">
                      Rifiuta
                    </button>
                  </div>
                </div>
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Richiesta Materiale</p>
                    <p className="text-sm text-gray-500">Luca Bianchi - Chiavi inglesi</p>
                  </div>
                  <div className="flex space-x-2">
                    <button className="px-3 py-1 text-xs font-medium bg-green-100 text-green-800 rounded hover:bg-green-200">
                      Approva
                    </button>
                    <button className="px-3 py-1 text-xs font-medium bg-red-100 text-red-800 rounded hover:bg-red-200">
                      Rifiuta
                    </button>
                  </div>
                </div>
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div>
                    <p className="font-medium text-gray-900">Richiesta Permesso</p>
                    <p className="text-sm text-gray-500">Anna Verdi - Visita medica</p>
                  </div>
                  <div className="flex space-x-2">
                    <button className="px-3 py-1 text-xs font-medium bg-green-100 text-green-800 rounded hover:bg-green-200">
                      Approva
                    </button>
                    <button className="px-3 py-1 text-xs font-medium bg-red-100 text-red-800 rounded hover:bg-red-200">
                      Rifiuta
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}