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

    // Get team members with user details
    async getMembers(teamId) {
        const { data, error } = await supabase
            .from('team_members')
            .select(`
                user_id,
                ruolo_squadra,
                users (
                    id,
                    nome,
                    cognome,
                    email,
                    ruolo
                )
            `)
            .eq('team_id', teamId);
        
        if (error) throw error;
        
        // Flatten user data into member object
        return data.map(member => ({
            user_id: member.user_id,
            ruolo_squadra: member.ruolo_squadra,
            nome: member.users.nome,
            cognome: member.users.cognome,
            email: member.users.email,
            ruolo: member.users.ruolo
        }));
    },

    // Get teams for a specific user
    async getUserTeams(userId) {
        const { data, error } = await supabase
            .from('team_members')
            .select(`
                team_id,
                ruolo_squadra,
                teams (
                    id,
                    nome,
                    descrizione,
                    colore
                )
            `)
            .eq('user_id', userId);
        
        if (error) throw error;
        
        // Return array of team IDs
        return data.map(tm => tm.team_id);
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

    // Get component by ID
    async getById(id) {
        const { data, error } = await supabase
            .from('components')
            .select('*')
            .eq('id', id)
            .single();
        
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
                client:clients(id, ragione_sociale, email, indirizzo, citta, cap),
                assigned_user:users!tasks_assigned_user_id_fkey(id, nome, cognome, email),
                assigned_team:teams(id, nome)
            `)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        // Normalize data - flatten client info
        return data.map(task => ({
            ...task,
            client_name: task.client?.ragione_sociale || 'N/A',
            client_address: task.client?.indirizzo || null,
            client_city: task.client?.citta || null,
            client_zip: task.client?.cap || null,
            user_name: task.assigned_user ? `${task.assigned_user.nome} ${task.assigned_user.cognome}` : null,
            team_name: task.assigned_team?.nome || null
        }));
    },

    // Get task by ID
    async getById(id) {
        const { data, error } = await supabase
            .from('tasks')
            .select(`
                *,
                client:clients(id, ragione_sociale, email, indirizzo, citta, cap),
                assigned_user:users!tasks_assigned_user_id_fkey(id, nome, cognome, email),
                assigned_team:teams(id, nome)
            `)
            .eq('id', id)
            .single();
        
        if (error) throw error;
        
        // Normalize data
        return {
            ...data,
            client_name: data.client?.ragione_sociale || 'N/A',
            client_address: data.client?.indirizzo || null,
            client_city: data.client?.citta || null,
            client_zip: data.client?.cap || null,
            user_name: data.assigned_user ? `${data.assigned_user.nome} ${data.assigned_user.cognome}` : null,
            team_name: data.assigned_team?.nome || null
        };
    },

    // Get tasks for user
    async getForUser(userId) {
        const { data, error } = await supabase
            .from('tasks')
            .select(`
                *,
                client:clients(id, ragione_sociale, email, indirizzo, citta, cap),
                assigned_user:users!tasks_assigned_user_id_fkey(id, nome, cognome, email),
                assigned_team:teams(id, nome)
            `)
            .or(`assigned_user_id.eq.${userId}`)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
        // Normalize data
        return data.map(task => ({
            ...task,
            client_name: task.client?.ragione_sociale || 'N/A',
            client_address: task.client?.indirizzo || null,
            client_city: task.client?.citta || null,
            client_zip: task.client?.cap || null,
            user_name: task.assigned_user ? `${task.assigned_user.nome} ${task.assigned_user.cognome}` : null,
            team_name: task.assigned_team?.nome || null
        }));
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
    async addComponent(taskId, componentId, quantita, note = '') {
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
        
        // Do NOT update quantity here - only when task is completed
        return data;
    },

    // Remove component from task
    async removeComponent(taskComponentId) {
        const { error } = await supabase
            .from('task_components')
            .delete()
            .eq('id', taskComponentId);
        
        if (error) throw error;
        
        // Do NOT restore quantity - only deduct when task is completed
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
    },

    // Deduct components when task is completed
    async deductComponentsOnCompletion(taskId) {
        // Get all components for this task
        const components = await this.getComponents(taskId);
        
        // Deduct quantity from each component
        for (const taskComponent of components) {
            await window.ComponentsAPI.updateQuantity(
                taskComponent.component_id,
                -taskComponent.quantita
            );
        }
        
        return components;
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
    },

    // Archive communication for a user
    async archiveCommunication(id, userId) {
        const { data: comm, error: fetchError } = await supabase
            .from('communications')
            .select('archiviata_da')
            .eq('id', id)
            .single();
        
        if (fetchError) throw fetchError;
        
        const archiviata = comm.archiviata_da || [];
        if (!archiviata.includes(userId)) {
            archiviata.push(userId);
            
            const { error } = await supabase
                .from('communications')
                .update({ archiviata_da: archiviata })
                .eq('id', id);
            
            if (error) throw error;
        }
    },

    // Unarchive communication for a user
    async unarchiveCommunication(id, userId) {
        const { data: comm, error: fetchError } = await supabase
            .from('communications')
            .select('archiviata_da')
            .eq('id', id)
            .single();
        
        if (fetchError) throw fetchError;
        
        const archiviata = (comm.archiviata_da || []).filter(uid => uid !== userId);
        
        const { error } = await supabase
            .from('communications')
            .update({ archiviata_da: archiviata })
            .eq('id', id);
        
        if (error) throw error;
    },

    // Delete communication for a user (soft delete with tracking)
    async deleteCommunicationForUser(id, userId) {
        const { data: comm, error: fetchError } = await supabase
            .from('communications')
            .select('eliminata_da')
            .eq('id', id)
            .single();
        
        if (fetchError) throw fetchError;
        
        const eliminata = comm.eliminata_da || [];
        
        // Check if already deleted by this user
        const alreadyDeleted = eliminata.find(item => item.user_id === userId);
        if (!alreadyDeleted) {
            eliminata.push({
                user_id: userId,
                deleted_at: new Date().toISOString()
            });
            
            const { error } = await supabase
                .from('communications')
                .update({ eliminata_da: eliminata })
                .eq('id', id);
            
            if (error) throw error;
        }
    },

    // Get all deletions (for admin panel) with user details
    async getDeletions() {
        const { data, error } = await supabase
            .from('communications')
            .select('id, titolo, tipo, eliminata_da, created_at')
            .not('eliminata_da', 'eq', '[]');
        
        if (error) throw error;
        
        // Enrich with user data
        if (data && data.length > 0) {
            // Collect all unique user IDs from eliminata_da
            const userIds = new Set();
            data.forEach(comm => {
                const eliminataData = Array.isArray(comm.eliminata_da) ? comm.eliminata_da : [];
                eliminataData.forEach(deletion => {
                    if (deletion.user_id) userIds.add(deletion.user_id);
                });
            });
            
            // Fetch user data for all IDs
            if (userIds.size > 0) {
                const { data: users, error: userError } = await supabase
                    .from('users')
                    .select('id, nome, cognome, email')
                    .in('id', Array.from(userIds));
                
                if (!userError && users) {
                    // Create user lookup map
                    const userMap = {};
                    users.forEach(user => {
                        userMap[user.id] = user;
                    });
                    
                    // Enrich deletion data with user info
                    data.forEach(comm => {
                        if (Array.isArray(comm.eliminata_da)) {
                            comm.eliminata_da = comm.eliminata_da.map(deletion => ({
                                ...deletion,
                                user: userMap[deletion.user_id] || null
                            }));
                        }
                    });
                }
            }
        }
        
        return data;
    },

    // Get all users (for admin selection)
    async getAllUsers() {
        const { data, error } = await supabase
            .from('users')
            .select('id, nome, cognome, email, ruolo')
            .order('nome', { ascending: true });
        
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

// =====================================================
// STORAGE API (for attachments)
// =====================================================
window.StorageAPI = {
    BUCKET_NAME: 'communications-attachments',

    // Upload file to storage
    async uploadFile(file, folder = 'attachments') {
        try {
            const timestamp = Date.now();
            const fileExt = file.name.split('.').pop();
            const fileName = `${folder}/${timestamp}_${Math.random().toString(36).substring(7)}.${fileExt}`;
            
            const { data, error } = await supabase.storage
                .from(this.BUCKET_NAME)
                .upload(fileName, file, {
                    cacheControl: '3600',
                    upsert: false
                });
            
            if (error) throw error;
            
            // Get public URL
            const { data: { publicUrl } } = supabase.storage
                .from(this.BUCKET_NAME)
                .getPublicUrl(fileName);
            
            return {
                path: fileName,
                url: publicUrl,
                name: file.name,
                size: file.size,
                type: file.type
            };
        } catch (error) {
            console.error('Error uploading file:', error);
            throw error;
        }
    },

    // Upload multiple files
    async uploadFiles(files, folder = 'attachments') {
        const uploadPromises = Array.from(files).map(file => this.uploadFile(file, folder));
        return Promise.all(uploadPromises);
    },

    // Delete file from storage
    async deleteFile(filePath) {
        try {
            const { error } = await supabase.storage
                .from(this.BUCKET_NAME)
                .remove([filePath]);
            
            if (error) throw error;
            return true;
        } catch (error) {
            console.error('Error deleting file:', error);
            throw error;
        }
    },

    // Get public URL for a file
    getPublicUrl(filePath) {
        const { data } = supabase.storage
            .from(this.BUCKET_NAME)
            .getPublicUrl(filePath);
        
        return data.publicUrl;
    },

    // List files in a folder
    async listFiles(folder = 'attachments') {
        try {
            const { data, error } = await supabase.storage
                .from(this.BUCKET_NAME)
                .list(folder);
            
            if (error) throw error;
            return data;
        } catch (error) {
            console.error('Error listing files:', error);
            throw error;
        }
    }
};

console.log('✅ Supabase Client initialized');
