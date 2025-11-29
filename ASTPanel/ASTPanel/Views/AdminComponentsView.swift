//
//  AdminComponentsView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

// MARK: - Admin Components View
struct AdminComponentsView: View {
    @State private var components: [Component] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showNewComponent = false
    @State private var selectedComponent: Component?
    @State private var showEditComponent = false
    @State private var showDeleteAlert = false
    @State private var componentToDelete: Component?
    
    private var filteredComponents: [Component] {
        if searchText.isEmpty {
            return components
        }
        return components.filter {
            $0.nome.localizedCaseInsensitiveContains(searchText) ||
            (($0.categoria ?? "").localizedCaseInsensitiveContains(searchText)) ||
            (($0.fornitore ?? "").localizedCaseInsensitiveContains(searchText))
        }
    }
    
    private var totalComponents: Int {
        components.count
    }
    
    private var lowStockComponents: Int {
        components.filter { component in
            if let quantita = component.quantita, let scorta = component.scortaMinima {
                return quantita <= scorta && quantita > 0
            }
            return false
        }.count
    }
    
    private var outOfStockComponents: Int {
        components.filter { component in
            (component.quantita ?? 0) == 0
        }.count
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Caricamento magazzino...")
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Statistics
                        HStack(spacing: 12) {
                            ComponentStatCard(
                                title: "Totale",
                                value: "\(totalComponents)",
                                icon: "cube.box.fill",
                                color: .blue
                            )
                            ComponentStatCard(
                                title: "Scorta Bassa",
                                value: "\(lowStockComponents)",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                            ComponentStatCard(
                                title: "Esauriti",
                                value: "\(outOfStockComponents)",
                                icon: "xmark.circle.fill",
                                color: .red
                            )
                        }
                        .padding(.horizontal)
                        
                        // Components List
                        LazyVStack(spacing: 12) {
                            ForEach(filteredComponents) { component in
                                ComponentCard(component: component) {
                                    selectedComponent = component
                                    showEditComponent = true
                                } onDelete: {
                                    componentToDelete = component
                                    showDeleteAlert = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Magazzino")
        .searchable(text: $searchText, prompt: "Cerca componenti...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showNewComponent = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .fullScreenCover(isPresented: $showNewComponent) {
            NewComponentView(onSave: loadComponents)
        }
        .fullScreenCover(item: $selectedComponent) { component in
            EditComponentView(component: component, onSave: loadComponents)
        }
        .alert("Elimina Componente", isPresented: $showDeleteAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Elimina", role: .destructive) {
                if let component = componentToDelete {
                    deleteComponent(component)
                }
            }
        } message: {
            Text("Sei sicuro di voler eliminare il componente \(componentToDelete?.nome ?? "")?")
        }
        .onAppear {
            loadComponents()
        }
    }
    
    private func loadComponents() {
        Task {
            do {
                components = try await SupabaseService.shared.fetch(from: "components")
                isLoading = false
            } catch {
                print("❌ Error loading components: \(error)")
                isLoading = false
            }
        }
    }
    
    private func deleteComponent(_ component: Component) {
        Task {
            do {
                try await SupabaseService.shared.delete(from: "components", id: component.id)
                loadComponents()
            } catch {
                print("❌ Error deleting component: \(error)")
            }
        }
    }
}

// MARK: - Component Stat Card
struct ComponentStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Component Card
struct ComponentCard: View {
    let component: Component
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var stockStatus: (color: Color, icon: String) {
        let quantita = component.quantita ?? 0
        let scorta = component.scortaMinima ?? 0
        
        if quantita == 0 {
            return (.red, "xmark.circle.fill")
        } else if quantita <= scorta {
            return (.orange, "exclamationmark.triangle.fill")
        } else {
            return (.green, "checkmark.circle.fill")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cube.box.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(component.nome)
                        .font(.headline)
                    
                    if let categoria = component.categoria {
                        Text(categoria)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: stockStatus.icon)
                    .foregroundColor(stockStatus.color)
                
                Menu {
                    Button(action: onEdit) {
                        Label("Modifica", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Elimina", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantità")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(component.quantita ?? 0) \(component.unitaMisura ?? "pz")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let prezzo = component.prezzo {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Prezzo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "€ %.2f", prezzo))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            if let fornitore = component.fornitore {
                HStack {
                    Image(systemName: "building.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(fornitore)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - New Component View
struct NewComponentView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: () -> Void
    
    @State private var nome = ""
    @State private var categoria = ""
    @State private var quantita = ""
    @State private var unitaMisura = "pz"
    @State private var prezzo = ""
    @State private var scortaMinima = ""
    @State private var fornitore = ""
    @State private var note = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Componente") {
                    TextField("Nome Componente *", text: $nome)
                    TextField("Categoria", text: $categoria)
                    TextField("Fornitore", text: $fornitore)
                }
                
                Section("Quantità e Prezzi") {
                    HStack {
                        TextField("Quantità *", text: $quantita)
                            .keyboardType(.numberPad)
                        TextField("Unità", text: $unitaMisura)
                            .frame(width: 80)
                    }
                    
                    TextField("Prezzo Unitario (€)", text: $prezzo)
                        .keyboardType(.decimalPad)
                    
                    TextField("Scorta Minima", text: $scortaMinima)
                        .keyboardType(.numberPad)
                }
                
                Section("Note") {
                    TextField("Note aggiuntive", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Nuovo Componente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveComponent()
                    }
                    .disabled(nome.isEmpty || quantita.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveComponent() {
        isSaving = true
        Task {
            do {
                var newComponent: [String: Any] = [
                    "nome": nome,
                    "quantita": Int(quantita) ?? 0,
                    "unita_misura": unitaMisura
                ]
                
                if !categoria.isEmpty {
                    newComponent["categoria"] = categoria
                }
                if !fornitore.isEmpty {
                    newComponent["fornitore"] = fornitore
                }
                if let prezzoValue = Double(prezzo.replacingOccurrences(of: ",", with: ".")), prezzoValue > 0 {
                    newComponent["prezzo"] = prezzoValue
                }
                if let scortaValue = Int(scortaMinima), scortaValue > 0 {
                    newComponent["scorta_minima"] = scortaValue
                }
                if !note.isEmpty {
                    newComponent["note"] = note
                }
                
                try await SupabaseService.shared.insert(into: "components", data: newComponent)
                
                onSave()
                dismiss()
            } catch {
                print("❌ Error saving component: \(error)")
                isSaving = false
            }
        }
    }
}

// MARK: - Edit Component View
struct EditComponentView: View {
    @Environment(\.dismiss) var dismiss
    let component: Component
    let onSave: () -> Void
    
    @State private var nome = ""
    @State private var categoria = ""
    @State private var quantita = ""
    @State private var unitaMisura = ""
    @State private var prezzo = ""
    @State private var scortaMinima = ""
    @State private var fornitore = ""
    @State private var note = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Componente") {
                    TextField("Nome Componente *", text: $nome)
                    TextField("Categoria", text: $categoria)
                    TextField("Fornitore", text: $fornitore)
                }
                
                Section("Quantità e Prezzi") {
                    HStack {
                        TextField("Quantità *", text: $quantita)
                            .keyboardType(.numberPad)
                        TextField("Unità", text: $unitaMisura)
                            .frame(width: 80)
                    }
                    
                    TextField("Prezzo Unitario (€)", text: $prezzo)
                        .keyboardType(.decimalPad)
                    
                    TextField("Scorta Minima", text: $scortaMinima)
                        .keyboardType(.numberPad)
                }
                
                Section("Note") {
                    TextField("Note aggiuntive", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Modifica Componente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        updateComponent()
                    }
                    .disabled(nome.isEmpty || quantita.isEmpty || isSaving)
                }
            }
            .onAppear {
                nome = component.nome
                categoria = component.categoria ?? ""
                quantita = "\(component.quantita ?? 0)"
                unitaMisura = component.unitaMisura ?? "pz"
                prezzo = component.prezzo != nil ? String(format: "%.2f", component.prezzo!) : ""
                scortaMinima = component.scortaMinima != nil ? "\(component.scortaMinima!)" : ""
                fornitore = component.fornitore ?? ""
                note = component.note ?? ""
            }
        }
    }
    
    private func updateComponent() {
        isSaving = true
        Task {
            do {
                var updatedData: [String: Any] = [
                    "nome": nome,
                    "quantita": Int(quantita) ?? 0,
                    "unita_misura": unitaMisura
                ]
                
                if !categoria.isEmpty {
                    updatedData["categoria"] = categoria
                }
                if !fornitore.isEmpty {
                    updatedData["fornitore"] = fornitore
                }
                if let prezzoValue = Double(prezzo.replacingOccurrences(of: ",", with: ".")), prezzoValue > 0 {
                    updatedData["prezzo"] = prezzoValue
                }
                if let scortaValue = Int(scortaMinima), scortaValue > 0 {
                    updatedData["scorta_minima"] = scortaValue
                }
                if !note.isEmpty {
                    updatedData["note"] = note
                }
                
                try await SupabaseService.shared.update(table: "components", id: component.id.uuidString, data: updatedData)
                
                onSave()
                dismiss()
            } catch {
                print("❌ Error updating component: \(error)")
                isSaving = false
            }
        }
    }
}
