// =====================================================
// AST PANEL - Supabase Client & API
// =====================================================

// Configurazione Supabase
const SUPABASE_URL = 'https://hrqhckksrunniqnzqogk.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhycWhja2tzcnVubmlxbnpxb2drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyODczNjUsImV4cCI6MjA3Njg2MzM2NX0.EyJc6p88SDxDt07g4sytrrqqnoA6EOvpKmoZFNCaqvA';

// Inizializza client Supabase
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// =====================================================
// AUTHENTICATION
// =====================================================
window.AuthService = {
    // Login
    async login(email, password) {
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
        });
        
        if (error) throw error;
        return data;
    },

    // Logout
    async logout() {
        const { error } = await supabase.auth.signOut();
        if (error) throw error;
    },

    // Get current user
    async getCurrentUser() {
        const { data: { user }, error } = await supabase.auth.getUser();
        if (error) throw error;
        return user;
    },

    // Get user session
    async getSession() {
        const { data: { session }, error } = await supabase.auth.getSession();
        if (error) throw error;
        return session;
    }
};

// =====================================================
// USERS API
// =====================================================
window.UsersAPI = {
    // Get all users
    async getAll() {
        const { data, error } = await supabase
            .from('users')
            .select('*')
            .order('nome', { ascending: true });
        
        if (error) throw error;
        return data;
    },

    // Get user by ID
    async getById(id) {
        const { data, error } = await supabase
            .from('users')
            .select('*')
            .eq('id', id)
            .single();
        
        if (error) throw error;
        return data;
    },

    // Create user
    async create(userData) {
        const { data, error } = await supabase
            .from('users')
            .insert([userData])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Update user
    async update(id, updates) {
        const { data, error } = await supabase
            .from('users')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Delete user
    async delete(id) {
        const { error } = await supabase
            .from('users')
            .delete()
            .eq('id', id);
        
        if (error) throw error;
    },

    // Get by role
    async getByRole(ruolo) {
        const { data, error } = await supabase
            .from('users')
            .select('*')
            .eq('ruolo', ruolo)
            .eq('stato', 'attivo');
        
        if (error) throw error;
        return data;
    }
};

// =====================================================
// CLIENTS API
// =====================================================
window.ClientsAPI = {
    // Get all clients
    async getAll() {
        const { data, error } = await supabase
            .from('clients')
            .select('*')
            .order('ragione_sociale', { ascending: true });
        
        if (error) throw error;
        return data;
    },

    // Get client by ID
    async getById(id) {
        const { data, error } = await supabase
            .from('clients')
            .select('*')
            .eq('id', id)
            .single();
        
        if (error) throw error;
        return data;
    },

    // Create client
    async create(clientData) {
        const { data, error } = await supabase
            .from('clients')
            .insert([clientData])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Update client
    async update(id, updates) {
        const { data, error } = await supabase
            .from('clients')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Delete client
    async delete(id) {
        const { error } = await supabase
            .from('clients')
            .delete()
            .eq('id', id);
        
        if (error) throw error;
    },

    // Search clients
    async search(searchTerm) {
        const { data, error } = await supabase
            .from('clients')
            .select('*')
            .or(`ragione_sociale.ilike.%${searchTerm}%,nome.ilike.%${searchTerm}%,cognome.ilike.%${searchTerm}%`);
        
        if (error) throw error;
        return data;
    }
};

// =====================================================
// TEAMS API
// =====================================================
window.TeamsAPI = {
    // Get all teams with members
    async getAll() {
        const { data, error } = await supabase
            .from('teams_with_members')
            .select('*');
        
        if (error) throw error;
        return data;
    },

    // Get team by ID
    async getById(id) {
        const { data, error } = await supabase
            .from('teams_with_members')
            .select('*')
            .eq('id', id)
            .single();
        
        if (error) throw error;
        return data;
    },

    // Create team
    async create(teamData, memberIds) {
        // Create team
        const { data: team, error: teamError } = await supabase
            .from('teams')
            .insert([{
                nome: teamData.nome,
                descrizione: teamData.descrizione,
                colore: teamData.colore
            }])
            .select()
            .single();
        
        if (teamError) throw teamError;

        // Add members
        if (memberIds && memberIds.length > 0) {
            const members = memberIds.map(userId => ({
                team_id: team.id,
                user_id: userId
            }));

            const { error: membersError } = await supabase
                .from('team_members')
                .insert(members);
            
            if (membersError) throw membersError;
        }

        return await this.getById(team.id);
    },

    // Update team
    async update(id, teamData, memberIds) {
        // Update team info
        const { error: teamError } = await supabase
            .from('teams')
            .update({
                nome: teamData.nome,
                descrizione: teamData.descrizione,
                colore: teamData.colore
            })
            .eq('id', id);
        
        if (teamError) throw teamError;

        // Update members
        if (memberIds !== undefined) {
            // Delete existing members
            await supabase
                .from('team_members')
                .delete()
                .eq('team_id', id);

            // Add new members
            if (memberIds.length > 0) {
                const members = memberIds.map(userId => ({
                    team_id: id,
                    user_id: userId
                }));

                const { error: membersError } = await supabase
                    .from('team_members')
                    .insert(members);
                
                if (membersError) throw membersError;
            }
        }

        return await this.getById(id);
    },

    // Delete team
    async delete(id) {
        const { error } = await supabase
            .from('teams')
            .delete()
            .eq('id', id);
        
        if (error) throw error;
    }
};

// =====================================================
// COMPONENTS API
// =====================================================
window.ComponentsAPI = {
    // Get all components
    async getAll() {
        const { data, error } = await supabase
            .from('components')
            .select('*')
            .order('categoria', { ascending: true });
        
        if (error) throw error;
        return data;
    },

    // Get by category
    async getByCategory(categoria) {
        const { data, error } = await supabase
            .from('components')
            .select('*')
            .eq('categoria', categoria);
        
        if (error) throw error;
        return data;
    },

    // Create component
    async create(componentData) {
        const { data, error } = await supabase
            .from('components')
            .insert([componentData])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Update component
    async update(id, updates) {
        const { data, error } = await supabase
            .from('components')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Update quantity
    async updateQuantity(id, quantityChange) {
        const component = await this.getById(id);
        const newQuantity = component.quantita_disponibile + quantityChange;
        
        return await this.update(id, { quantita_disponibile: newQuantity });
    }
};

// =====================================================
// TASKS API
// =====================================================
window.TasksAPI = {
    // Get all tasks (complete view)
    async getAll() {
        const { data, error } = await supabase
            .from('tasks')
            .select(`
                *,
                client:clients(id, ragione_sociale, email),
                assigned_user:users!tasks_assigned_user_id_fkey(id, nome, cognome, email),
                assigned_team:teams(id, nome)
            `)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        // Normalize data - flatten client info
        return data.map(task => ({
            ...task,
            client_name: task.client?.ragione_sociale || 'N/A',
            user_name: task.assigned_user ? `${task.assigned_user.nome} ${task.assigned_user.cognome}` : null,
            team_name: task.assigned_team?.nome || null
        }));
    },

    // Get task by ID
    async getById(id) {
        const { data, error } = await supabase
            .from('tasks_complete')
            .select('*')
            .eq('id', id)
            .single();
        
        if (error) throw error;
        return data;
    },

    // Get tasks for user
    async getForUser(userId) {
        const { data, error } = await supabase
            .from('tasks_complete')
            .select('*')
            .or(`assigned_user_id.eq.${userId},assigned_team_id.in.(SELECT team_id FROM team_members WHERE user_id = ${userId})`);
        
        if (error) throw error;
        return data;
    },

    // Create task
    async create(taskData) {
        const { data, error } = await supabase
            .from('tasks')
            .insert([taskData])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Update task
    async update(id, updates) {
        const { data, error } = await supabase
            .from('tasks')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Delete task
    async delete(id) {
        const { error } = await supabase
            .from('tasks')
            .delete()
            .eq('id', id);
        
        if (error) throw error;
    },

    // Add component to task
    async addComponent(taskId, componentId, quantita, note) {
        const { data, error } = await supabase
            .from('task_components')
            .insert([{
                task_id: taskId,
                component_id: componentId,
                quantita: quantita,
                note: note
            }])
            .select()
            .single();
        
        if (error) throw error;

        // Update component quantity
        await window.ComponentsAPI.updateQuantity(componentId, -quantita);
        
        return data;
    },

    // Remove component from task
    async removeComponent(taskComponentId) {
        // Get task component to restore quantity
        const { data: taskComponent, error: fetchError } = await supabase
            .from('task_components')
            .select('*')
            .eq('id', taskComponentId)
            .single();
        
        if (fetchError) throw fetchError;

        // Delete task component
        const { error } = await supabase
            .from('task_components')
            .delete()
            .eq('id', taskComponentId);
        
        if (error) throw error;

        // Restore component quantity
        await window.ComponentsAPI.updateQuantity(
            taskComponent.component_id, 
            taskComponent.quantita
        );
    },

    // Get task components
    async getComponents(taskId) {
        const { data, error } = await supabase
            .from('task_components')
            .select(`
                *,
                component:components(*)
            `)
            .eq('task_id', taskId);
        
        if (error) throw error;
        return data;
    }
};

// =====================================================
// REQUESTS API
// =====================================================
window.RequestsAPI = {
    // Get all requests
    async getAll() {
        const { data, error } = await supabase
            .from('requests')
            .select(`
                *,
                user:users!user_id(*),
                responder:users!risposto_da(*)
            `)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        return data;
    },

    // Get requests for user
    async getForUser(userId) {
        const { data, error } = await supabase
            .from('requests')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        return data;
    },

    // Create request
    async create(requestData) {
        const { data, error } = await supabase
            .from('requests')
            .insert([requestData])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Update request
    async update(id, updates) {
        const { data, error } = await supabase
            .from('requests')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Respond to request
    async respond(id, risposta, rispostoDa, stato = 'approvata') {
        return await this.update(id, {
            risposta,
            risposto_da: rispostoDa,
            risposto_il: new Date().toISOString(),
            stato
        });
    }
};

// =====================================================
// COMMUNICATIONS API
// =====================================================
window.CommunicationsAPI = {
    // Get all communications
    async getAll() {
        const { data, error } = await supabase
            .from('communications')
            .select(`
                *,
                publisher:users!pubblicato_da(*)
            `)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        return data;
    },

    // Create communication
    async create(commData) {
        const { data, error } = await supabase
            .from('communications')
            .insert([commData])
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Update communication
    async update(id, updates) {
        const { data, error } = await supabase
            .from('communications')
            .update(updates)
            .eq('id', id)
            .select()
            .single();
        
        if (error) throw error;
        return data;
    },

    // Delete communication
    async delete(id) {
        const { error } = await supabase
            .from('communications')
            .delete()
            .eq('id', id);
        
        if (error) throw error;
    },

    // Mark as read
    async markAsRead(id, userId) {
        const comm = await this.getById(id);
        const lettaDa = comm.letta_da || [];
        
        if (!lettaDa.includes(userId)) {
            lettaDa.push(userId);
            
            const { error } = await supabase
                .from('communications')
                .update({ letta_da: lettaDa })
                .eq('id', id);
            
            if (error) throw error;
        }
    },

    async getById(id) {
        const { data, error } = await supabase
            .from('communications')
            .select('*')
            .eq('id', id)
            .single();
        
        if (error) throw error;
        return data;
    }
};

// =====================================================
// REALTIME SUBSCRIPTIONS
// =====================================================
window.RealtimeService = {
    subscriptions: [],

    // Subscribe to table changes
    subscribe(table, callback) {
        const subscription = supabase
            .channel(`${table}_changes`)
            .on('postgres_changes', 
                { event: '*', schema: 'public', table: table },
                callback
            )
            .subscribe();

        this.subscriptions.push(subscription);
        return subscription;
    },

    // Unsubscribe all
    unsubscribeAll() {
        this.subscriptions.forEach(sub => {
            supabase.removeChannel(sub);
        });
        this.subscriptions = [];
    }
};

console.log('✅ Supabase Client initialized');
