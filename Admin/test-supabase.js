// Test connessione Supabase
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://hjadqekxoaaxdjstuepn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqYWRxZWt4b2FheGRqc3R1ZXBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzAwMjcwNjksImV4cCI6MjA0NTYwMzA2OX0.Sjs99fnDVG1xJ0Vd8l0-s7Vn7B-ZM_6gzYRD1QOLdQI';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testConnection() {
    console.log('🔍 Testando connessione Supabase...');
    
    try {
        // Test 1: Check health
        const { data, error } = await supabase.from('users').select('count').limit(1);
        
        if (error) {
            console.log('❌ Errore connessione:', error.message);
            return false;
        }
        
        console.log('✅ Connessione Supabase OK');
        
        // Test 2: Count users
        const { data: users, error: usersError } = await supabase
            .from('users')
            .select('id, full_name, role');
            
        if (usersError) {
            console.log('❌ Errore lettura utenti:', usersError.message);
        } else {
            console.log(`👥 Trovati ${users.length} utenti`);
            users.forEach(user => {
                console.log(`   - ${user.full_name} (${user.role})`);
            });
        }
        
        // Test 3: Count requests
        const { data: requests, error: reqError } = await supabase
            .from('requests')
            .select('id, type, status')
            .eq('status', 'pending');
            
        if (reqError) {
            console.log('❌ Errore lettura richieste:', reqError.message);
        } else {
            console.log(`📝 Trovate ${requests.length} richieste pendenti`);
            requests.forEach(req => {
                console.log(`   - ${req.type} (${req.status})`);
            });
        }
        
        return true;
        
    } catch (error) {
        console.log('💥 Errore generale:', error.message);
        return false;
    }
}

testConnection().then(success => {
    if (success) {
        console.log('\n🎉 Database è raggiungibile e funzionante!');
    } else {
        console.log('\n🚨 Problemi con il database - i pulsanti non funzioneranno');
    }
});