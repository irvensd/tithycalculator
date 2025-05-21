//
//  ContentView.swift
//  Tithycalculator
//
//  Created by Irvens Dupuy on 5/7/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - GivingCategory
struct GivingCategory: Identifiable, Equatable, Codable {
    var id = UUID()
    let name: String
    var percentage: Double
    var colorName: String // Store color as string name
    let description: String
    
    // Define CodingKeys
    private enum CodingKeys: String, CodingKey {
        case id, name, percentage, colorName, description
    }
    
    // Computed property for color
    var color: Color {
        switch colorName {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        default: return .green
        }
    }
    
    init(id: UUID = UUID(), name: String, percentage: Double, color: Color, description: String) {
        self.id = id
        self.name = name
        self.percentage = percentage
        
        // Convert Color to colorName
        if color == .green { self.colorName = "green" }
        else if color == .blue { self.colorName = "blue" }
        else if color == .orange { self.colorName = "orange" }
        else if color == .purple { self.colorName = "purple" }
        else if color == .red { self.colorName = "red" }
        else { self.colorName = "green" }
        
        self.description = description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        percentage = try container.decode(Double.self, forKey: .percentage)
        let colorName = try container.decode(String.self, forKey: .colorName)
        self.colorName = colorName
        description = try container.decode(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(percentage, forKey: .percentage)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(description, forKey: .description)
    }
    
    static let defaultPresets: [GivingCategory] = [
        GivingCategory(
            name: "Tithiq",
            percentage: 10.0,
            color: .green,
            description: "Traditional 10% giving based on biblical principles."
        ),
        GivingCategory(
            name: "Offering",
            percentage: 5.0,
            color: .blue,
            description: "Additional giving beyond the tithe to support special needs."
        ),
        GivingCategory(
            name: "Missions",
            percentage: 3.0,
            color: .orange,
            description: "Support for missionaries and outreach programs."
        )
    ]
    
    static var preset: [GivingCategory] {
        return CategoryManager.shared.categories
    }
}

// MARK: - CategoryManager
class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    @Published var categories: [GivingCategory] = []
    private let categoriesKey = "givingCategories"
    
    init() {
        loadCategories()
        // If no categories are loaded, use the defaults
        if categories.isEmpty {
            categories = GivingCategory.defaultPresets
            saveCategories()
        }
    }
    
    func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(data, forKey: categoriesKey)
        } catch {
            print("Failed to save categories: \(error)")
        }
    }
    
    private func loadCategories() {
        guard let data = UserDefaults.standard.data(forKey: categoriesKey) else { return }
        
        do {
            categories = try JSONDecoder().decode([GivingCategory].self, from: data)
        } catch {
            print("Failed to load categories: \(error)")
            categories = GivingCategory.defaultPresets
        }
    }
    
    func resetToDefaults() {
        categories = GivingCategory.defaultPresets
        saveCategories()
    }
}

// MARK: - TitheRecord
struct TitheRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let income: Double
    let frequency: String
    let categoryName: String
    let categoryPercentage: Double
    let givingAmount: Double
    
    // For displaying in the UI
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedIncome: String {
        String(format: "$%.2f", income)
    }
    
    var formattedGiving: String {
        String(format: "$%.2f", givingAmount)
    }
    
    var formattedPercentage: String {
        String(format: "%.1f%%", categoryPercentage)
    }
}

// MARK: - HistoryManager
class HistoryManager: ObservableObject {
    @Published var records: [TitheRecord] = []
    private let recordsKey = "titheRecords"
    private let maxRecords = 20 // Limit to 20 most recent records
    
    init() {
        loadRecords()
    }
    
    func addRecord(income: Double, frequency: String, categoryName: String, categoryPercentage: Double, givingAmount: Double) {
        let newRecord = TitheRecord(
            date: Date(),
            income: income,
            frequency: frequency,
            categoryName: categoryName,
            categoryPercentage: categoryPercentage,
            givingAmount: givingAmount
        )
        
        records.insert(newRecord, at: 0) // Add to beginning of array (most recent first)
        
        // Limit the number of records
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        
        saveRecords()
    }
    
    func deleteRecord(at indices: IndexSet) {
        records.remove(atOffsets: indices)
        saveRecords()
    }
    
    func clearAllRecords() {
        records.removeAll()
        saveRecords()
    }
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([TitheRecord].self, from: data) {
            records = decoded
        }
    }
    
    // Get all records for a specific month and year
    func recordsForMonth(month: Int, year: Int) -> [TitheRecord] {
        let calendar = Calendar.current
        return records.filter { record in
            let components = calendar.dateComponents([.month, .year], from: record.date)
            return components.month == month && components.year == year
        }
    }
    
    // Get total giving by month
    func getTotalByMonth(month: Int, year: Int) -> Double {
        return recordsForMonth(month: month, year: year).reduce(0) { $0 + $1.givingAmount }
    }
    
    // Get category breakdown for a month
    func getCategoryBreakdownForMonth(month: Int, year: Int) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        let monthRecords = recordsForMonth(month: month, year: year)
        
        for record in monthRecords {
            breakdown[record.categoryName, default: 0] += record.givingAmount
        }
        
        return breakdown
    }
    
    // Get monthly summary
    func getMonthlySummary(month: Int, year: Int) -> MonthSummary {
        let monthRecords = recordsForMonth(month: month, year: year)
        let totalGiving = monthRecords.reduce(0) { $0 + $1.givingAmount }
        let categoryBreakdown = getCategoryBreakdownForMonth(month: month, year: year)
        let givenDates = monthRecords.map { $0.date }
        
        return MonthSummary(
            month: month,
            year: year,
            totalGiving: totalGiving,
            categoryBreakdown: categoryBreakdown,
            givenDates: givenDates
        )
    }
    
    // Get yearly breakdown
    func getYearlyBreakdown(year: Int) -> YearlyBreakdown {
        let calendar = Calendar.current
        let yearRecords = records.filter { calendar.component(.year, from: $0.date) == year }
        
        let totalGiving = yearRecords.reduce(0) { $0 + $1.givingAmount }
        
        // Monthly breakdown
        var monthlyTotals: [Int: Double] = [:]
        for record in yearRecords {
            let month = calendar.component(.month, from: record.date)
            monthlyTotals[month, default: 0] += record.givingAmount
        }
        
        // Category breakdown
        var categoryTotals: [String: Double] = [:]
        for record in yearRecords {
            categoryTotals[record.categoryName, default: 0] += record.givingAmount
        }
        
        return YearlyBreakdown(
            year: year,
            totalGiving: totalGiving,
            monthlyTotals: monthlyTotals,
            categoryTotals: categoryTotals
        )
    }
    
    // Get recent months (for display in monthly view)
    func getRecentMonths(count: Int = 12) -> [(month: Int, year: Int)] {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        var result: [(month: Int, year: Int)] = []
        for i in 0..<count {
            var components = DateComponents()
            components.month = -i
            if let date = calendar.date(byAdding: components, to: currentDate) {
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                result.append((month: month, year: year))
            }
        }
        
        return result
    }
    
    // Export data as CSV string
    func exportAsCSV() -> String {
        var csv = "Date,Category,Percentage,Amount,Frequency\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for record in records {
            let dateStr = dateFormatter.string(from: record.date)
            let line = "\(dateStr),\(record.categoryName),\(record.categoryPercentage)%,\(record.givingAmount),\(record.frequency)\n"
            csv.append(line)
        }
        
        return csv
    }
}

// MARK: - MonthSummary
struct MonthSummary: Identifiable {
    var id = UUID()
    let month: Int // 1-12
    let year: Int
    let totalGiving: Double
    let categoryBreakdown: [String: Double]
    let givenDates: [Date]
    
    var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = month
        components.year = year
        if let date = calendar.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return "Unknown"
    }
    
    var formattedTotal: String {
        return String(format: "$%.2f", totalGiving)
    }
    
    // Count of giving instances
    var givingCount: Int {
        return givenDates.count
    }
}

// MARK: - YearlyBreakdown
struct YearlyBreakdown {
    let year: Int
    let totalGiving: Double
    let monthlyTotals: [Int: Double] // month: amount
    let categoryTotals: [String: Double] // category: amount
    
    var formattedTotal: String {
        return String(format: "$%.2f", totalGiving)
    }
}

// MARK: - HistoryView
struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(.trailing)
                            .padding(.top)
                    }
                }
                
                Text("Calculation History")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                if historyManager.records.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Calculation History")
                            .font(.headline)
                        
                        Text("Your giving calculations will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(historyManager.records) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(record.formattedDate)
                                        .font(.headline)
                                    Spacer()
                                    Text(record.frequency)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Income:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(record.formattedIncome)
                                            .font(.subheadline)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(record.categoryName) (\(record.formattedPercentage)):")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(record.formattedGiving)
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: historyManager.deleteRecord)
                    }
                    .listStyle(PlainListStyle())
                    
                    Button(action: {
                        withAnimation {
                            historyManager.clearAllRecords()
                        }
                    }) {
                        Text("Clear All History")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - GivingGoal
struct GivingGoal: Codable {
    var monthlyTarget: Double = 0
    var yearlyTarget: Double = 0
}

// MARK: - GoalsManager
class GoalsManager: ObservableObject {
    @Published var goals = GivingGoal()
    private let goalsKey = "givingGoals"
    
    init() {
        loadGoals()
    }
    
    func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: goalsKey)
        }
    }
    
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode(GivingGoal.self, from: data) {
            goals = decoded
        }
    }
}

// MARK: - GoalsView
struct GoalsView: View {
    @ObservedObject var goalsManager: GoalsManager
    @Environment(\.dismiss) private var dismiss
    @State private var monthlyText = ""
    @State private var yearlyText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(.trailing)
                            .padding(.top)
                    }
                }
                
                Text("Your Giving Goals")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                VStack(spacing: 20) {
                    // Monthly Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Giving Goal")
                            .font(.headline)
                        
                        HStack {
                            Text("$")
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: $monthlyText)
                                .onAppear {
                                    if goalsManager.goals.monthlyTarget > 0 {
                                        monthlyText = String(format: "%.2f", goalsManager.goals.monthlyTarget)
                                    }
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Yearly Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yearly Giving Goal")
                            .font(.headline)
                        
                        HStack {
                            Text("$")
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: $yearlyText)
                                .onAppear {
                                    if goalsManager.goals.yearlyTarget > 0 {
                                        yearlyText = String(format: "%.2f", goalsManager.goals.yearlyTarget)
                                    }
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        // Save goals
                        goalsManager.goals.monthlyTarget = Double(monthlyText) ?? 0
                        goalsManager.goals.yearlyTarget = Double(yearlyText) ?? 0
                        goalsManager.saveGoals()
                        dismiss()
                    }) {
                        Text("Save Goals")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct CategoryButton: View {
    let category: GivingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text("\(String(format: "%.1f", category.percentage))%")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color.gray.opacity(0.1))
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - MultiSelectionGivingView
struct MultiSelectionGivingView: View {
    let categories: [GivingCategory]
    @Binding var selectedCategories: [GivingCategory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Giving Categories")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories) { category in
                        let isSelected = selectedCategories.contains { $0.id == category.id }
                        
                        MultiCategoryButton(
                            category: category,
                            isSelected: isSelected,
                            action: {
                                if isSelected {
                                    selectedCategories.removeAll { $0.id == category.id }
                                } else {
                                    selectedCategories.append(category)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !selectedCategories.isEmpty {
                let categories = selectedCategories.map { $0.name }.joined(separator: ", ")
                Text("Selected: \(categories)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
}

struct MultiCategoryButton: View {
    let category: GivingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text("\(String(format: "%.1f", category.percentage))%")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? category.color : Color.gray.opacity(0.1))
            )
            .overlay(
                isSelected ?
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(4)
                    .offset(x: 8, y: -8)
                    .opacity(0.9)
                : nil,
                alignment: .topTrailing
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - CategorySelectionView
struct CategorySelectionView: View {
    let categories: [GivingCategory]
    @Binding var selectedCategory: GivingCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Giving Category")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory.id == category.id,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            
            Text(selectedCategory.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.horizontal)
    }
}

// MARK: - IncomeInputView
struct IncomeInputView: View {
    @Binding var incomeText: String
    @FocusState var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter Your Income")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("$")
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $incomeText)
                    .focused($isInputFocused)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

// MARK: - FrequencySelectionView
struct FrequencySelectionView: View {
    @Binding var frequency: String
    let frequencies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Income Frequency")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Frequency", selection: $frequency) {
                ForEach(frequencies, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }
}

// MARK: - ProjectionsView
struct ProjectionsView: View {
    let monthlyGiving: Double
    let annualGiving: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Projections")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Monthly")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(monthlyGiving, specifier: "%.2f")")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Annually")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(annualGiving, specifier: "%.2f")")
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - BibleVerse
struct BibleVerse: Identifiable {
    var id = UUID()
    let reference: String
    let text: String
    
    static let givingVerses: [BibleVerse] = [
        BibleVerse(
            reference: "Proverbs 3:9-10",
            text: "Honor the LORD with your wealth, with the firstfruits of all your crops; then your barns will be filled to overflowing, and your vats will brim over with new wine."
        ),
        BibleVerse(
            reference: "2 Corinthians 9:7",
            text: "Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver."
        ),
        BibleVerse(
            reference: "Malachi 3:10",
            text: "Bring the whole tithe into the storehouse, that there may be food in my house. Test me in this, says the LORD Almighty, and see if I will not throw open the floodgates of heaven and pour out so much blessing that there will not be room enough to store it."
        ),
        BibleVerse(
            reference: "Matthew 6:21",
            text: "For where your treasure is, there your heart will be also."
        ),
        BibleVerse(
            reference: "Acts 20:35",
            text: "In everything I did, I showed you that by this kind of hard work we must help the weak, remembering the words the Lord Jesus himself said: 'It is more blessed to give than to receive.'"
        ),
        BibleVerse(
            reference: "Luke 6:38",
            text: "Give, and it will be given to you. A good measure, pressed down, shaken together and running over, will be poured into your lap. For with the measure you use, it will be measured to you."
        ),
        BibleVerse(
            reference: "1 Timothy 6:17-19",
            text: "Command those who are rich in this present world not to be arrogant nor to put their hope in wealth, which is so uncertain, but to put their hope in God, who richly provides us with everything for our enjoyment. Command them to do good, to be rich in good deeds, and to be generous and willing to share."
        ),
        BibleVerse(
            reference: "Hebrews 13:16",
            text: "And do not forget to do good and to share with others, for with such sacrifices God is pleased."
        )
    ]
}

// MARK: - VerseView
struct VerseView: View {
    let verse: BibleVerse
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scripture on Giving")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("\"\(verse.text)\"")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        isAnimating = true
                    }
                }
            
            HStack {
                Spacer()
                Text("— \(verse.reference)")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 10)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: isAnimating)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - RotatingVersesView
struct RotatingVersesView: View {
    @State private var currentVerseIndex = 0
    @State private var opacity = 1.0
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            VerseView(verse: BibleVerse.givingVerses[currentVerseIndex])
                .opacity(opacity)
                .onReceive(timer) { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        currentVerseIndex = (currentVerseIndex + 1) % BibleVerse.givingVerses.count
                        
                        withAnimation(.easeIn(duration: 0.5)) {
                            opacity = 1.0
                        }
                    }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentVerseIndex = (currentVerseIndex + 1) % BibleVerse.givingVerses.count
                
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1.0
                }
            }
        }
    }
}

// MARK: - ActionButtonsView
struct ActionButtonsView: View {
    let income: Double
    let saveAction: () -> Void
    let clearAction: () -> Void
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Save Button
            Button(action: saveAction) {
                Text("Save to History")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(income > 0 ? color : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(income <= 0)
            
            // Clear Button
            Button(action: clearAction) {
                Text("Clear")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - ResultView
struct ResultView: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    @State private var animateValue = false
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(color)
                .scaleEffect(animateValue ? 1.0 : 0.9)
                .opacity(animateValue ? 1.0 : 0.5)
                .onAppear {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateValue = true
                    }
                }
                .onChange(of: value) { _ in
                    animateValue = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateValue = true
                    }
                }
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - ProgressBar
struct ProgressBar: View {
    var value: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(color)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(color)
                    .animation(.linear, value: value)
            }
            .cornerRadius(45)
        }
    }
}

// MARK: - ProgressTracker
class ProgressTracker: ObservableObject {
    @Published var yearlyProgress: [ProgressEntry] = []
    private let progressKey = "yearlyProgressData"
    
    struct ProgressEntry: Identifiable, Codable {
        var id = UUID()
        let date: Date
        let amount: Double
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        
        var month: Int {
            Calendar.current.component(.month, from: date)
        }
        
        var monthName: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            return formatter.string(from: date)
        }
    }
    
    init() {
        loadProgress()
    }
    
    func addContribution(amount: Double) {
        let newEntry = ProgressEntry(date: Date(), amount: amount)
        yearlyProgress.append(newEntry)
        saveProgress()
    }
    
    func clearYearlyData() {
        yearlyProgress.removeAll()
        saveProgress()
    }
    
    func totalContributions() -> Double {
        return yearlyProgress.reduce(0) { $0 + $1.amount }
    }
    
    func monthlyTotals() -> [Int: Double] {
        var totals: [Int: Double] = [:]
        
        for entry in yearlyProgress {
            let month = entry.month
            totals[month, default: 0] += entry.amount
        }
        
        return totals
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(yearlyProgress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode([ProgressEntry].self, from: data) {
            yearlyProgress = decoded
        }
    }
}

// MARK: - ProgressView
struct ProgressDashboardView: View {
    @ObservedObject var progressTracker: ProgressTracker
    @ObservedObject var goalsManager: GoalsManager
    @State private var contributionAmount = ""
    @State private var showingAlert = false
    
    private var yearlyTotal: Double {
        return progressTracker.totalContributions()
    }
    
    private var yearlyGoalProgress: Double {
        guard goalsManager.goals.yearlyTarget > 0 else { return 0 }
        return min(yearlyTotal / goalsManager.goals.yearlyTarget, 1.0)
    }
    
    private var monthlyData: [Int: Double] {
        return progressTracker.monthlyTotals()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Yearly progress section
                    VStack(spacing: 16) {
                        Text("Yearly Giving Progress")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Goal Progress
                        VStack(spacing: 12) {
                            HStack {
                                Text("Total Given")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text(String(format: "$%.2f", yearlyTotal))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            if goalsManager.goals.yearlyTarget > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Goal: $\(goalsManager.goals.yearlyTarget, specifier: "%.2f")")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(yearlyGoalProgress * 100))%")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                    }
                                    
                                    ProgressBar(value: yearlyGoalProgress, color: .green)
                                        .frame(height: 12)
                                }
                            } else {
                                Button(action: {
                                    showingAlert = true
                                }) {
                                    Text("Set Yearly Goal")
                                        .foregroundColor(.blue)
                                }
                                .alert(isPresented: $showingAlert) {
                                    Alert(
                                        title: Text("Set a Goal"),
                                        message: Text("Go to the Calculator tab and tap the target icon to set goals."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Month by month breakdown
                        if !monthlyData.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Monthly Breakdown")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                ForEach(Array(monthlyData.keys.sorted()), id: \.self) { month in
                                    if let amount = monthlyData[month] {
                                        HStack {
                                            Text(monthName(month))
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Text(String(format: "$%.2f", amount))
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Quick add contribution
                        VStack(spacing: 12) {
                            Text("Add Contribution")
                                .font(.headline)
                            
                            HStack {
                                Text("$")
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", text: $contributionAmount)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            
                            Button(action: {
                                if let amount = Double(contributionAmount), amount > 0 {
                                    progressTracker.addContribution(amount: amount)
                                    contributionAmount = ""
                                }
                            }) {
                                Text("Add to Progress")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(Double(contributionAmount) ?? 0 <= 0)
                            
                            Button(action: {
                                progressTracker.clearYearlyData()
                            }) {
                                Text("Reset Progress")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Giving Progress")
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var comps = DateComponents()
        comps.month = month
        if let date = Calendar.current.date(from: comps) {
            return formatter.string(from: date)
        }
        return ""
    }
}

// MARK: - ScreenshotView
struct ScreenshotView: View {
    let amount: String
    let percentage: String
    let income: String
    let frequency: String
    let categories: String
    let date: Date
    let verse: BibleVerse
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : Color.white)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // App Title
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.green)
                    Text("Tithiq")
                        .font(.title2)
                        .fontWeight(.bold)
                    Image(systemName: "heart.fill")
                        .foregroundColor(.green)
                }
                .padding(.top)
                
                // Main Amount
                VStack(spacing: 8) {
                    Text("My Giving")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text(amount)
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.vertical, 8)
                    
                    Text(percentage + " of " + income)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text(frequency)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical)
                
                // Categories
                VStack(spacing: 6) {
                    Text("Categories")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(categories)
                        .font(.title3)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom)
                
                // Bible Verse
                VStack(spacing: 10) {
                    Text("\"\(verse.text)\"")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                    
                    Text("— \(verse.reference)")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical)
                
                Spacer()
                
                // Date
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Close Button
                Button("Done") {
                    dismiss()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .frame(maxWidth: 500)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Calculator View
struct CalculatorView: View {
    @State private var incomeText = ""
    @State private var frequency = "Monthly"
    @FocusState private var isInputFocused: Bool
    @State private var showingHistory = false
    @State private var showingGoals = false
    @State private var showingScreenshot = false
    @State private var showingTaxInfo = false // Add this line
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var goalsManager: GoalsManager
    @ObservedObject var progressTracker: ProgressTracker
    @State private var selectedCategories: [GivingCategory] = [GivingCategory.preset[0]] // Default to Tithe
    @StateObject private var presetManager = PresetManager()
    
    private let frequencies = ["Weekly", "Bi-Weekly", "Monthly", "Annually"]
    
    private var income: Double {
        return Double(incomeText) ?? 0
    }
    
    private var totalPercentage: Double {
        return selectedCategories.reduce(0) { $0 + $1.percentage }
    }
    
    private var givingAmount: Double {
        return income * (totalPercentage / 100.0)
    }
    
    private var monthlyIncome: Double {
        switch frequency {
        case "Weekly":
            return income * 4.33 // Average weeks in a month
        case "Bi-Weekly":
            return income * 2.17 // Average bi-weekly periods in a month
        case "Annually":
            return income / 12
        default:
            return income // Monthly is already monthly
        }
    }
    
    private var monthlyGiving: Double {
        return monthlyIncome * (totalPercentage / 100.0)
    }
    
    private var annualGiving: Double {
        switch frequency {
        case "Weekly":
            return givingAmount * 52
        case "Bi-Weekly":
            return givingAmount * 26
        case "Monthly":
            return givingAmount * 12
        default:
            return givingAmount // Annual is already annual
        }
    }
    
    private var monthlyGoalProgress: Double {
        guard goalsManager.goals.monthlyTarget > 0 else { return 0 }
        return min(monthlyGiving / goalsManager.goals.monthlyTarget, 1.0)
    }
    
    private var yearlyGoalProgress: Double {
        guard goalsManager.goals.yearlyTarget > 0 else { return 0 }
        return min(annualGiving / goalsManager.goals.yearlyTarget, 1.0)
    }
    
    private func clearValues() {
        withAnimation(.easeInOut(duration: 0.3)) {
            incomeText = ""
        }
    }
    
    private func saveCalculation() {
        if income > 0 {
            withAnimation {
                let categoryNames = selectedCategories.map { $0.name }.joined(separator: ", ")
                historyManager.addRecord(
                    income: income,
                    frequency: frequency,
                    categoryName: categoryNames,
                    categoryPercentage: totalPercentage,
                    givingAmount: givingAmount
                )
                
                // Add to progress tracker if saving
                progressTracker.addContribution(amount: givingAmount)
                
                // Save as last giving preset
                let categoryDistribution = Dictionary(uniqueKeysWithValues:
                    selectedCategories.map { ($0.name, $0.percentage / totalPercentage * 100.0) }
                )
                presetManager.updateLastGiving(
                    amount: income,
                    frequency: frequency,
                    categories: selectedCategories.map { $0.name },
                    categoryDistribution: categoryDistribution
                )
            }
            
            // Provide haptic feedback
            #if canImport(UIKit)
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
            #endif
        }
    }
    
    // Extracted header view to simplify main body
    private var headerView: some View {
        HStack {
            Text("Tithiq")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    showingScreenshot = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                }
                .disabled(income <= 0)
                
                Button(action: {
                    showingGoals = true
                }) {
                    Image(systemName: "target")
                        .font(.title2)
                }
                
                Button(action: {
                    showingTaxInfo = true
                }) {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                }
                
                Button(action: {
                    showingHistory = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    // Extracted keyboard done button to simplify main body
    private var keyboardDoneButton: some View {
        Group {
            if isInputFocused {
                HStack {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                    }
                    .padding()
                }
                .background(Color.secondary.opacity(0.1))
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    // Main results section
    private var resultsSection: some View {
        VStack(spacing: 16) {
            // Giving Result
            ResultView(
                title: "Total Giving (\(String(format: "%.1f", totalPercentage))%)",
                value: String(format: "$%.2f", givingAmount),
                subtitle: "per \(frequency.lowercased()) income",
                color: selectedCategories.first?.color ?? .green
            )
            
            // Monthly and Annual Projection
            VStack(spacing: 16) {
                // Monthly Projection with Goal
                VStack(spacing: 8) {
                    HStack {
                        Text("Monthly")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("$\(monthlyGiving, specifier: "%.2f")")
                            .font(.headline)
                    }
                    
                    if goalsManager.goals.monthlyTarget > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Goal: $\(goalsManager.goals.monthlyTarget, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(monthlyGoalProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressBar(value: monthlyGoalProgress, color: .blue)
                                .frame(height: 8)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Yearly Projection with Goal
                VStack(spacing: 8) {
                    HStack {
                        Text("Yearly")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("$\(annualGiving, specifier: "%.2f")")
                            .font(.headline)
                    }
                    
                    if goalsManager.goals.yearlyTarget > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Goal: $\(goalsManager.goals.yearlyTarget, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(yearlyGoalProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressBar(value: yearlyGoalProgress, color: .green)
                                .frame(height: 8)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Bible Verse
            RotatingVersesView()
                .padding(.horizontal)
            
            // Category Breakdown if multiple selected
            if selectedCategories.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category Breakdown")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ForEach(selectedCategories) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                            
                            Text(category.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(String(format: "%.1f", category.percentage))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("$\(income * (category.percentage / 100.0), specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(category.color)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    var body: some View {
        VStack {
            // Header
            headerView
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Presets Section (new)
                    QuickPresetsView(
                        presetManager: presetManager,
                        incomeText: $incomeText,
                        frequency: $frequency,
                        selectedCategories: $selectedCategories
                    )
                    
                    // Category Selection
                    MultiSelectionGivingView(
                        categories: GivingCategory.preset,
                        selectedCategories: $selectedCategories
                    )
                    
                    // Income Input
                    IncomeInputView(
                        incomeText: $incomeText,
                        isInputFocused: _isInputFocused
                    )
                    
                    // Frequency Selection
                    FrequencySelectionView(
                        frequency: $frequency,
                        frequencies: frequencies
                    )
                    
                    // Results
                    resultsSection
                    
                    // Action Buttons
                    ActionButtonsView(
                        income: income,
                        saveAction: saveCalculation,
                        clearAction: clearValues,
                        color: selectedCategories.first?.color ?? .green
                    )
                    
                    Spacer()
                }
                .padding(.top)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(historyManager: historyManager)
            }
            .sheet(isPresented: $showingTaxInfo) {
                TaxInformationView()
            }
            .sheet(isPresented: $showingGoals) {
                GoalsView(goalsManager: goalsManager)
            }
            .sheet(isPresented: $showingScreenshot) {
                ScreenshotView(
                    amount: String(format: "$%.2f", givingAmount),
                    percentage: String(format: "%.1f%%", totalPercentage),
                    income: String(format: "$%.2f", income),
                    frequency: frequency,
                    categories: selectedCategories.map { $0.name }.joined(separator: ", "),
                    date: Date(),
                    verse: BibleVerse.givingVerses.randomElement() ?? BibleVerse.givingVerses[0]
                )
            }
            .sheet(isPresented: $showingTaxInfo) {
                TaxInformationView()
            }
            
            // Keyboard done button
            keyboardDoneButton
        }
        .onTapGesture {
            isInputFocused = false
        }
        // Add animation when income or category changes
        .onChange(of: incomeText) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // This triggers animation of dependent values
            }
        }
        .onChange(of: selectedCategories) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // This triggers animation of dependent values when category changes
            }
        }
        .onChange(of: frequency) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // This triggers animation of dependent values when frequency changes
            }
        }
    }
}

// MARK: - CategorySettingsItemView
struct CategorySettingsItemView: View {
    @Binding var category: GivingCategory
    let formatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header with color
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(category.color)
                    .frame(width: 4, height: 20)
                
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(category.color)
                
                Spacer()
                
                Circle()
                    .fill(category.color)
                    .frame(width: 16, height: 16)
            }
            
            // Percentage slider
            VStack(spacing: 6) {
                HStack {
                    Text("Percentage:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    TextField("", value: $category.percentage, formatter: formatter)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    
                    Text("%")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $category.percentage, in: 0...50, step: 0.5)
                    .accentColor(category.color)
            }
            
            // Description
            Text(category.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - PrivacySettingsView
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isBiometricLockEnabled = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data Privacy")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Privacy Matters")
                            .font(.headline)
                        
                        Text("• All your giving data is stored locally on your device")
                            .font(.subheadline)
                        
                        Text("• No personal information is collected or shared with external servers")
                            .font(.subheadline)
                        
                        Text("• Reminders are handled locally and never leave your device")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Data Management"), footer: Text("Clear all your giving history and settings.")) {
                    Button(action: {
                        // This would handle data export in a real app
                    }) {
                        Label("Export Your Data", systemImage: "arrow.down.doc")
                    }
                    
                    Button(action: {
                        // This would show a confirmation dialog in a real app
                    }) {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("App Security"), footer: Text("Enable this to add an extra layer of protection.")) {
                    Toggle("App Lock", isOn: $isBiometricLockEnabled)
                    
                    if isBiometricLockEnabled {
                        Text("App will be locked with Face ID, Touch ID, or device passcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Privacy & Security")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @ObservedObject var categoryManager = CategoryManager.shared
    @ObservedObject var reminderManager = ReminderManager()
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var editedCategories: [GivingCategory] = []
    @State private var showResetAlert = false
    @State private var showSavedMessage = false
    @State private var showingReminderSettings = false
    @State private var showingPrivacySettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AppearanceSection(themeManager: themeManager)
                    CustomizeHeader()
                    CategoriesSection(editedCategories: $editedCategories, formatter: percentageFormatter)
                    PrivacySecuritySection(showingPrivacySettings: $showingPrivacySettings)
                    RemindersSection(reminderManager: reminderManager, showingReminderSettings: $showingReminderSettings)
                    TipJarSection()
                    ActionsSection(
                        categoryManager: categoryManager,
                        editedCategories: $editedCategories,
                        showSavedMessage: $showSavedMessage,
                        showResetAlert: $showResetAlert
                    )
                    Spacer()
                }
            }
            .onAppear {
                editedCategories = categoryManager.categories
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showResetAlert) {
                Alert(
                    title: Text("Reset Categories"),
                    message: Text("This will reset all category percentages to their default values. Continue?"),
                    primaryButton: .destructive(Text("Reset")) {
                        categoryManager.resetToDefaults()
                        editedCategories = categoryManager.categories
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private var percentageFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }
}

// MARK: - AppearanceSection
private struct AppearanceSection: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Appearance")
                .font(.headline)
                .padding(.horizontal)
            
            VStack {
                Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                    .onChange(of: themeManager.isDarkMode) { newValue in
                        themeManager.impactFeedback()
                    }
                
                Toggle("Enable Haptic Feedback", isOn: $themeManager.isHapticEnabled)
                    .onChange(of: themeManager.isHapticEnabled) { newValue in
                        if newValue {
                            themeManager.impactFeedback()
                        }
                    }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - CustomizeHeader
private struct CustomizeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Customize Your Giving")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Adjust the percentages for each giving category")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
}

// MARK: - CategoriesSection
private struct CategoriesSection: View {
    @Binding var editedCategories: [GivingCategory]
    let formatter: NumberFormatter
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<editedCategories.count, id: \.self) { index in
                CategorySettingsItemView(
                    category: $editedCategories[index],
                    formatter: formatter
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - PrivacySecuritySection
private struct PrivacySecuritySection: View {
    @Binding var showingPrivacySettings: Bool
    
    var body: some View {
        Button(action: {
            showingPrivacySettings = true
        }) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy & Security")
                        .font(.headline)
                    
                    Text("Your data stays on your device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
    }
}

// MARK: - RemindersSection
private struct RemindersSection: View {
    @ObservedObject var reminderManager: ReminderManager
    @Binding var showingReminderSettings: Bool
    
    var body: some View {
        Button(action: {
            showingReminderSettings = true
        }) {
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundColor(reminderManager.preferences.isEnabled ? .blue : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Giving Reminders")
                        .font(.headline)
                    
                    Text(reminderManager.preferences.isEnabled ?
                         reminderManager.formattedNextReminder() :
                         "Set up gentle reminders for your giving schedule")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView(reminderManager: reminderManager)
        }
    }
}

// MARK: - TipJarSection
private struct TipJarSection: View {
    var body: some View {
        Button(action: {
            print("Tip Jar button tapped")
        }) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Support Us with a Tip")
                        .font(.headline)
                    
                    Text("Help us improve by leaving a tip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - ActionsSection
private struct ActionsSection: View {
    @ObservedObject var categoryManager: CategoryManager
    @Binding var editedCategories: [GivingCategory]
    @Binding var showSavedMessage: Bool
    @Binding var showResetAlert: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                categoryManager.categories = editedCategories
                categoryManager.saveCategories()
                showSavedMessage = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSavedMessage = false
                }
            }) {
                HStack {
                    if showSavedMessage {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    Text(showSavedMessage ? "Saved" : "Save Changes")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                showResetAlert = true
            }) {
                Text("Reset to Default Values")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

// MARK: - MonthlyGivingView
struct MonthlyGivingView: View {
    @ObservedObject var historyManager: HistoryManager
    @ObservedObject var categoryManager: CategoryManager
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    @State private var showExportOptions = false
    
    init(historyManager: HistoryManager, categoryManager: CategoryManager) {
        self.historyManager = historyManager
        self.categoryManager = categoryManager
        
        // Initialize to current month/year
        let calendar = Calendar.current
        let currentDate = Date()
        _selectedMonth = State(initialValue: calendar.component(.month, from: currentDate))
        _selectedYear = State(initialValue: calendar.component(.year, from: currentDate))
    }
    
    private var monthlySummary: MonthSummary {
        historyManager.getMonthlySummary(month: selectedMonth, year: selectedYear)
    }
    
    private var categorySlices: [(name: String, value: Double, color: Color)] {
        var slices: [(name: String, value: Double, color: Color)] = []
        
        for (categoryName, amount) in monthlySummary.categoryBreakdown {
            // Find the matching category for color
            let categoryColor: Color
            if let category = categoryManager.categories.first(where: { $0.name == categoryName }) {
                categoryColor = category.color
            } else if categoryName.contains("Tithe") {
                categoryColor = .green
            } else if categoryName.contains("Offering") {
                categoryColor = .blue
            } else if categoryName.contains("Missions") {
                categoryColor = .orange
            } else {
                categoryColor = .gray
            }
            
            slices.append((name: categoryName, value: amount, color: categoryColor))
        }
        
        return slices
    }
    
    private var monthYearOptions: [(month: Int, year: Int)] {
        historyManager.getRecentMonths(count: 12)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Month selector
                    VStack(spacing: 8) {
                        Text("Monthly Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(monthName(month))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 120)
                            
                            Picker("Year", selection: $selectedYear) {
                                ForEach(2020...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                                    Text(String(year))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            Spacer()
                            
                            Button(action: {
                                showExportOptions = true
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Monthly total
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Given")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(monthlySummary.formattedTotal)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Giving Events")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(monthlySummary.givingCount)")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Pie chart
                    if !categorySlices.isEmpty {
                        VStack(spacing: 12) {
                            Text("Category Breakdown")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            PieChartView(slices: categorySlices)
                                .frame(height: 200)
                                .padding()
                            
                            // Legend
                            VStack(spacing: 8) {
                                ForEach(categorySlices, id: \.name) { slice in
                                    HStack {
                                        Circle()
                                            .fill(slice.color)
                                            .frame(width: 12, height: 12)
                                        
                                        Text(slice.name)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text(String(format: "$%.2f", slice.value))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        VStack {
                            Text("No giving recorded for this month")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Month history preview
                    VStack(spacing: 12) {
                        Text("Recent Months")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(monthYearOptions.prefix(6), id: \.month) { option in
                                    let summary = historyManager.getMonthlySummary(month: option.month, year: option.year)
                                    MonthHistoryCard(summary: summary)
                                        .onTapGesture {
                                            selectedMonth = option.month
                                            selectedYear = option.year
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Giving History")
            .alert(isPresented: $showExportOptions) {
                Alert(
                    title: Text("Export Options"),
                    message: Text("Your giving data is ready to export"),
                    primaryButton: .default(Text("Export CSV")) {
                        exportCSV()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return "Unknown"
    }
    
    private func exportCSV() {
        let csvString = historyManager.exportAsCSV()
        // In a real app, you would implement sharing or saving of the CSV
        print(csvString) // For demo purposes
    }
}

struct MonthHistoryCard: View {
    let summary: MonthSummary
    
    var body: some View {
        VStack(spacing: 8) {
            Text(summary.monthName)
                .font(.headline)
            
            Text(summary.formattedTotal)
                .font(.title3)
                .foregroundColor(summary.totalGiving > 0 ? .green : .secondary)
            
            Text("\(summary.givingCount) times")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 100)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Progress View
struct EnhancedProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    @ObservedObject var goalsManager: GoalsManager
    @ObservedObject var historyManager: HistoryManager
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    // Add a formatted string version without commas
    private var formattedYear: String {
        return "\(currentYear)"
    }
    
    private var yearlyBreakdown: YearlyBreakdown {
        historyManager.getYearlyBreakdown(year: currentYear)
    }
    
    private var yearlyProgress: Double {
        guard goalsManager.goals.yearlyTarget > 0 else { return 0 }
        return min(yearlyBreakdown.totalGiving / goalsManager.goals.yearlyTarget, 1.0)
    }
    
    private var monthlyData: [Int: Double] {
        return yearlyBreakdown.monthlyTotals
    }
    
    private var maxMonthlyAmount: Double {
        if let max = monthlyData.values.max() {
            return max > 0 ? max : 1
        }
        return 1
    }
    
    private var streakCount: Int {
        // Simple streak calculation - consecutive months with giving
        var count = 0
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        
        for month in (1...currentMonth).reversed() {
            if let amount = monthlyData[month], amount > 0 {
                count += 1
            } else {
                break
            }
        }
        
        return count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Year progress
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(formattedYear) Giving Progress")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            if goalsManager.goals.yearlyTarget > 0 {
                                Text(String(format: "$%.2f", yearlyBreakdown.totalGiving))
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Text("of")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "$%.2f", goalsManager.goals.yearlyTarget))
                                    .font(.headline)
                            } else {
                                Text(String(format: "$%.2f", yearlyBreakdown.totalGiving))
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if goalsManager.goals.yearlyTarget > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                ProgressBar(value: yearlyProgress, color: .green)
                                    .frame(height: 12)
                                
                                HStack {
                                    Text("\(Int(yearlyProgress * 100))% Complete")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if yearlyProgress < 1.0 {
                                        Text(String(format: "$%.2f Remaining", goalsManager.goals.yearlyTarget - yearlyBreakdown.totalGiving))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Goal Achieved! 🎉")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        } else {
                            Button(action: {
                                // Link to the goals section
                            }) {
                                Text("Set a yearly giving goal")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Monthly chart
                    VStack(spacing: 12) {
                        Text("Monthly Breakdown")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(1...12, id: \.self) { month in
                                let amount = monthlyData[month] ?? 0
                                let normalizedHeight = amount > 0 ? max(amount / maxMonthlyAmount * 100, 15) : 5
                                
                                VStack {
                                    Rectangle()
                                        .fill(amount > 0 ? Color.green : Color.gray.opacity(0.3))
                                        .frame(height: CGFloat(normalizedHeight))
                                        .cornerRadius(4)
                                    
                                    Text(String(month))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 120)
                        
                        if streakCount > 0 {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                
                                Text("\(streakCount) Month Streak!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Category breakdown for the year
                    if !yearlyBreakdown.categoryTotals.isEmpty {
                        VStack(spacing: 12) {
                            Text("Year-to-Date by Category")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(Array(yearlyBreakdown.categoryTotals.keys.sorted()), id: \.self) { category in
                                if let amount = yearlyBreakdown.categoryTotals[category] {
                                    let percentage = yearlyBreakdown.totalGiving > 0 ? amount / yearlyBreakdown.totalGiving : 0
                                    
                                    HStack {
                                        Text(category)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text(String(format: "$%.2f", amount))
                                            .font(.subheadline)
                                        
                                        Text(String(format: "(%.1f%%)", percentage * 100))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
        }
    }
}

// MARK: - PieChartView
struct PieChartView: View {
    var slices: [(name: String, value: Double, color: Color)]
    
    private var total: Double {
        slices.reduce(0) { $0 + $1.value }
    }
    
    private func calculateAngles() -> [Double] {
        var angles: [Double] = []
        var startAngle: Double = 0
        
        for slice in slices {
            let angle = 360 * (slice.value / total)
            angles.append(startAngle + angle)
            startAngle += angle
        }
        
        return angles
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height)
            let height = width
            
            ZStack {
                ForEach(0..<slices.count, id: \.self) { i in
                    PieSliceView(
                        startAngle: i == 0 ? 0 : calculateAngles()[i-1],
                        endAngle: calculateAngles()[i],
                        color: slices[i].color
                    )
                }
                
                Circle()
                    .fill(Color.white)
                    .frame(width: width * 0.5, height: height * 0.5)
                    .shadow(radius: 2)
                
                VStack {
                    Text(String(format: "$%.2f", total))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: width, height: height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct PieSliceView: View {
    var startAngle: Double
    var endAngle: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(endAngle - 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// MARK: - GivingPreset
struct GivingPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let amount: Double
    let frequency: String
    let categories: [String]
    let categoryDistribution: [String: Double] // Category name: percentage of total
    
    // Organization information (optional)
    let organizationName: String?
    let organizationDetails: String?
    
    init(name: String, amount: Double, frequency: String, categories: [String] = [],
         categoryDistribution: [String: Double] = [:], organizationName: String? = nil,
         organizationDetails: String? = nil) {
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.categories = categories
        self.categoryDistribution = categoryDistribution
        self.organizationName = organizationName
        self.organizationDetails = organizationDetails
    }
    
    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - PresetManager
class PresetManager: ObservableObject {
    @Published var presets: [GivingPreset] = []
    @Published var lastGiving: GivingPreset?
    private let presetsKey = "givingPresets"
    private let lastGivingKey = "lastGivingPreset"
    
    init() {
        loadPresets()
        loadLastGiving()
    }
    
    func addPreset(_ preset: GivingPreset) {
        presets.append(preset)
        savePresets()
    }
    
    func removePreset(at index: Int) {
        guard index < presets.count else { return }
        presets.remove(at: index)
        savePresets()
    }
    
    func updateLastGiving(amount: Double, frequency: String, categories: [String],
                         categoryDistribution: [String: Double]) {
        lastGiving = GivingPreset(
            name: "Last Time",
            amount: amount,
            frequency: frequency,
            categories: categories,
            categoryDistribution: categoryDistribution
        )
        saveLastGiving()
    }
    
    func savePresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: presetsKey)
        }
    }
    
    func saveLastGiving() {
        if let lastGiving = lastGiving, let encoded = try? JSONEncoder().encode(lastGiving) {
            UserDefaults.standard.set(encoded, forKey: lastGivingKey)
        }
    }
    
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let decoded = try? JSONDecoder().decode([GivingPreset].self, from: data) {
            presets = decoded
        } else {
            // Load default presets if none exist
            presets = [
                GivingPreset(name: "Weekly Tithe", amount: 100, frequency: "Weekly",
                            categories: ["Tithe"], categoryDistribution: ["Tithe": 100.0]),
                GivingPreset(name: "Monthly Giving", amount: 500, frequency: "Monthly",
                            categories: ["Tithe", "Offering"], categoryDistribution: ["Tithe": 80.0, "Offering": 20.0])
            ]
            savePresets()
        }
    }
    
    private func loadLastGiving() {
        if let data = UserDefaults.standard.data(forKey: lastGivingKey),
           let decoded = try? JSONDecoder().decode(GivingPreset.self, from: data) {
            lastGiving = decoded
        }
    }
}

// MARK: - PresetView
struct PresetView: View {
    let preset: GivingPreset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(preset.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Organization label if present
                    if let org = preset.organizationName {
                        Text(org)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(preset.formattedAmount)
                        .font(.title3)
                        .foregroundColor(.green)
                    
                    Text(preset.frequency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Category summary
                    if !preset.categories.isEmpty {
                        Text(preset.categories.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - QuickPresetsView
struct QuickPresetsView: View {
    @ObservedObject var presetManager: PresetManager
    @Binding var incomeText: String
    @Binding var frequency: String
    @Binding var selectedCategories: [GivingCategory]
    @State private var showingAddPreset = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Presets")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingAddPreset = true
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Last time preset (if available)
                    if let lastGiving = presetManager.lastGiving {
                        PresetView(preset: lastGiving) {
                            applyPreset(lastGiving)
                        }
                        .frame(width: 200)
                        .overlay(
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(6)
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 1)
                                .offset(x: -6, y: -6),
                            alignment: .topTrailing
                        )
                    }
                    
                    // Saved presets
                    ForEach(presetManager.presets) { preset in
                        PresetView(preset: preset) {
                            applyPreset(preset)
                        }
                        .frame(width: 200)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showingAddPreset) {
            // Simple form to add a new preset
            AddPresetView(presetManager: presetManager)
        }
    }
    
    private func applyPreset(_ preset: GivingPreset) {
        // Apply the preset to the calculator
        incomeText = String(format: "%.2f", preset.amount)
        frequency = preset.frequency
        
        // Apply category distribution if available
        if !preset.categoryDistribution.isEmpty {
            // Find matching categories
            var newCategories: [GivingCategory] = []
            
            for (categoryName, _) in preset.categoryDistribution {
                if let matchedCategory = GivingCategory.preset.first(where: { $0.name == categoryName }) {
                    newCategories.append(matchedCategory)
                }
            }
            
            // Update selected categories
            if !newCategories.isEmpty {
                selectedCategories = newCategories
            }
        }
    }
}

// MARK: - AddPresetView
struct AddPresetView: View {
    @ObservedObject var presetManager: PresetManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var presetName = ""
    @State private var amountText = ""
    @State private var selectedFrequency = "Monthly"
    @State private var organizationName = ""
    @State private var includeOrganization = false
    
    private let frequencies = ["Weekly", "Bi-Weekly", "Monthly", "Annually"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preset Details")) {
                    TextField("Name (e.g. Monthly Tithe)", text: $presetName)
                    
                    HStack {
                        Text("$")
                        #if os(iOS)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                        #else
                        TextField("Amount", text: $amountText)
                        #endif
                    }
                    
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(frequencies, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Organization")) {
                    Toggle("Include Organization", isOn: $includeOrganization)
                    
                    if includeOrganization {
                        TextField("Organization Name", text: $organizationName)
                    }
                }
                
                Section {
                    Button("Save Preset") {
                        savePreset()
                    }
                    .disabled(presetName.isEmpty || amountText.isEmpty)
                }
            }
            .navigationTitle("Add Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func savePreset() {
        guard let amount = Double(amountText), amount > 0 else { return }
        
        let newPreset = GivingPreset(
            name: presetName,
            amount: amount,
            frequency: selectedFrequency,
            organizationName: includeOrganization ? organizationName : nil
        )
        
        presetManager.addPreset(newPreset)
        dismiss()
    }
}

// MARK: - OnboardingView
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    
    let onboardingPages = [
        OnboardingPage(title: "Welcome to Tithiq", description: "Your personal giving calculator.", imageName: "heart.fill"),
        OnboardingPage(title: "Calculate Your Giving", description: "Enter your income and select your giving categories.", imageName: "function"),
        OnboardingPage(title: "Track Your Progress", description: "Monitor your giving goals and achievements.", imageName: "chart.bar.fill"),
        OnboardingPage(title: "Get Insights", description: "Receive personalized insights to enhance your giving journey.", imageName: "lightbulb.fill")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    VStack {
                        Image(systemName: onboardingPages[index].imageName)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding()
                        
                        Text(onboardingPages[index].title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding()
                        
                        Text(onboardingPages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            #endif
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentPage < onboardingPages.count - 1 {
                        currentPage += 1
                    } else {
                        UserDefaults.standard.set(true, forKey: "isOnboardingComplete")
                        isOnboardingComplete = true
                    }
                }
            }) {
                Text(currentPage < onboardingPages.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

// MARK: - ContentView (Main App View with Tabs)
struct ContentView: View {
    @StateObject private var historyManager = HistoryManager()
    @StateObject private var goalsManager = GoalsManager()
    @StateObject private var progressTracker = ProgressTracker()
    @StateObject private var categoryManager = CategoryManager.shared
    @StateObject private var insightsManager: InsightsManager
    @StateObject private var reminderManager = ReminderManager()
    @State private var selectedTab = 0
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete = false
    
    init() {
        // Initialize InsightsManager with default instances
        // We'll use the properties after view initialization
        let historyManagerTemp = HistoryManager()
        let goalsManagerTemp = GoalsManager()
        let categoryManagerTemp = CategoryManager.shared
        
        _insightsManager = StateObject(wrappedValue: InsightsManager(
            historyManager: historyManagerTemp,
            goalsManager: goalsManagerTemp,
            categoryManager: categoryManagerTemp
        ))
    }
    
    var body: some View {
        if !isOnboardingComplete {
            OnboardingView(isOnboardingComplete: $isOnboardingComplete)
        } else {
            TabView(selection: $selectedTab) {
                CalculatorView(
                    historyManager: historyManager,
                    goalsManager: goalsManager,
                    progressTracker: progressTracker
                )
                    .tabItem {
                    Label("Calculate", systemImage: "function")
                }
                .tag(0)
                
                EnhancedProgressView(
                    progressTracker: progressTracker,
                    goalsManager: goalsManager,
                    historyManager: historyManager
                )
                    .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                    }
                .tag(1)
                
                SmartInsightsView(insightsManager: insightsManager)
                    .tabItem {
                    Label("Insights", systemImage: "lightbulb.fill")
                    }
                .tag(2)
                
                MonthlyGivingView(
                    historyManager: historyManager,
                    categoryManager: categoryManager
                )
                    .tabItem {
                    Label("History", systemImage: "calendar")
                    }
                .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .accentColor(.blue)
            .onAppear {
                // Update insightsManager references after view initialization
                // This ensures we're using the same manager instances throughout
                DispatchQueue.main.async {
                    insightsManager.historyManager = historyManager
                    insightsManager.goalsManager = goalsManager
                    insightsManager.categoryManager = categoryManager
                    insightsManager.generateInsights()
                }
            }
            .onChange(of: selectedTab) { newTab in
                // Refresh insights when navigating to the Insights tab
                if newTab == 2 {
                    insightsManager.generateInsights()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - InsightsManager
class InsightsManager: ObservableObject {
    @Published var insights: [GivingInsight] = []
    @Published var categorySuggestions: [CategorySuggestion] = []
    @Published var yearEndProjection: YearEndProjection?
    
    var historyManager: HistoryManager
    var goalsManager: GoalsManager
    var categoryManager: CategoryManager
    
    struct GivingInsight: Identifiable {
        var id = UUID()
        let title: String
        let description: String
        let type: InsightType
        let iconName: String
        
        enum InsightType {
            case pattern
            case suggestion
            case achievement
        }
    }
    
    struct CategorySuggestion: Identifiable {
        var id = UUID()
        let categoryName: String
        let currentPercentage: Double
        let suggestedPercentage: Double
        let reason: String
        let color: Color
    }
    
    struct YearEndProjection {
        let currentTotal: Double
        let projectedTotal: Double
        let goalAmount: Double
        let monthsRemaining: Int
        let suggestedMonthlyAmount: Double
        
        var isOnTrack: Bool {
            return projectedTotal >= goalAmount
        }
        
        var percentToGoal: Double {
            guard goalAmount > 0 else { return 0 }
            return min(projectedTotal / goalAmount, 1.0)
        }
    }
    
    init(historyManager: HistoryManager, goalsManager: GoalsManager, categoryManager: CategoryManager) {
        self.historyManager = historyManager
        self.goalsManager = goalsManager
        self.categoryManager = categoryManager
        
        generateInsights()
    }
    
    func generateInsights() {
        analyzePatterns()
        analyzeCategoryBalance()
        generateYearEndProjection()
    }
    
    private func analyzePatterns() {
        insights.removeAll()
        
        // Get current year records
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        // Analyze giving frequency
        let yearBreakdown = historyManager.getYearlyBreakdown(year: currentYear)
        var activeMonths = 0
        
        for month in 1...currentMonth {
            if let amount = yearBreakdown.monthlyTotals[month], amount > 0 {
                activeMonths += 1
            }
        }
        
        let consistencyRate = Double(activeMonths) / Double(currentMonth)
        
        if consistencyRate >= 0.8 {
            insights.append(GivingInsight(
                title: "Consistent Giver",
                description: "You've given consistently in \(activeMonths) out of \(currentMonth) months this year. Great job maintaining regular giving!",
                type: .achievement,
                iconName: "star.fill"
            ))
        } else if consistencyRate >= 0.5 {
            insights.append(GivingInsight(
                title: "Building Consistency",
                description: "You've given in \(activeMonths) out of \(currentMonth) months. Setting up regular giving can help build consistency.",
                type: .pattern,
                iconName: "calendar.badge.clock"
            ))
        } else if activeMonths > 0 {
            insights.append(GivingInsight(
                title: "Occasional Giving",
                description: "You've given in \(activeMonths) out of \(currentMonth) months. Consider scheduling regular contributions.",
                type: .suggestion,
                iconName: "repeat.circle"
            ))
        }
        
        // Identify giving trends
        if currentMonth > 2 {
            let last3Months = (currentMonth-2...currentMonth).compactMap { month -> Double? in
                let total = historyManager.getTotalByMonth(month: month, year: currentYear)
                return total > 0 ? total : nil
            }
            
            if last3Months.count == 3 {
                if last3Months[0] < last3Months[1] && last3Months[1] < last3Months[2] {
                    insights.append(GivingInsight(
                        title: "Increasing Generosity",
                        description: "Your giving has increased each month for the last 3 months. Your growing generosity is making an impact!",
                        type: .achievement,
                        iconName: "arrow.up.right"
                    ))
                } else if last3Months[0] > last3Months[1] && last3Months[1] > last3Months[2] {
                    insights.append(GivingInsight(
                        title: "Decreasing Giving",
                        description: "Your giving has decreased over the last 3 months. Consider setting a minimum monthly giving goal.",
                        type: .pattern,
                        iconName: "arrow.down.right"
                    ))
                }
            }
        }
        
        // Identify favorite giving categories
        if !yearBreakdown.categoryTotals.isEmpty {
            let sortedCategories = yearBreakdown.categoryTotals.sorted { $0.value > $1.value }
            if let topCategory = sortedCategories.first {
                let percentage = topCategory.value / yearBreakdown.totalGiving * 100
                insights.append(GivingInsight(
                    title: "Favorite Category: \(topCategory.key)",
                    description: "\(Int(percentage))% of your giving goes toward \(topCategory.key). You're making a significant impact in this area!",
                    type: .pattern,
                    iconName: "heart.fill"
                ))
            }
        }
    }
    
    private func analyzeCategoryBalance() {
        categorySuggestions.removeAll()
        
        // Get current year records
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        let yearBreakdown = historyManager.getYearlyBreakdown(year: currentYear)
        
        // Skip if not enough data
        if yearBreakdown.totalGiving == 0 || yearBreakdown.categoryTotals.isEmpty {
            return
        }
        
        // Calculate ideal balanced distribution
        let categories = categoryManager.categories
        let idealBalance = 100.0 / Double(categories.count)
        
        // Check current distribution
        for category in categories {
            let actualAmount = yearBreakdown.categoryTotals[category.name] ?? 0
            let actualPercentage = (actualAmount / yearBreakdown.totalGiving) * 100
            
            // Suggest balancing if significantly off from category's configured percentage
            let configuredPercentage = category.percentage
            let targetRatio = configuredPercentage / category.percentage
            
            if actualPercentage < configuredPercentage * 0.7 {
                // Under-contributing to this category
                categorySuggestions.append(CategorySuggestion(
                    categoryName: category.name,
                    currentPercentage: actualPercentage,
                    suggestedPercentage: configuredPercentage,
                    reason: "You've allocated \(Int(actualPercentage))% to \(category.name) vs. your target of \(Int(configuredPercentage))%",
                    color: category.color
                ))
            } else if actualPercentage > configuredPercentage * 1.3 && actualPercentage > 60 {
                // Over-contributing to this category (only suggest if heavily weighted)
                categorySuggestions.append(CategorySuggestion(
                    categoryName: category.name,
                    currentPercentage: actualPercentage,
                    suggestedPercentage: configuredPercentage,
                    reason: "Consider diversifying from \(category.name) to increase impact across multiple areas",
                    color: category.color
                ))
            }
        }
    }
    
    private func generateYearEndProjection() {
        let calendar = Calendar.current
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        // Calculate months remaining in the year
        let monthsRemaining = 12 - currentMonth
        
        guard monthsRemaining > 0 else {
            // Year is complete
            return
        }
        
        // Get current year-to-date giving
        let yearlyBreakdown = historyManager.getYearlyBreakdown(year: currentYear)
        let currentTotal = yearlyBreakdown.totalGiving
        
        // Get yearly goal
        let yearlyGoal = goalsManager.goals.yearlyTarget
        
        // Calculate monthly average so far
        let monthlyAverage = currentTotal / Double(currentMonth)
        
        // Project end of year total
        let projectedTotal = currentTotal + (monthlyAverage * Double(monthsRemaining))
        
        // Calculate amount needed monthly to reach goal
        let remainingToGoal = max(0, yearlyGoal - currentTotal)
        let suggestedMonthlyAmount = monthsRemaining > 0 ? remainingToGoal / Double(monthsRemaining) : 0
        
        yearEndProjection = YearEndProjection(
            currentTotal: currentTotal,
            projectedTotal: projectedTotal,
            goalAmount: yearlyGoal,
            monthsRemaining: monthsRemaining,
            suggestedMonthlyAmount: suggestedMonthlyAmount
        )
        
        // Add year-end insight
        if yearlyGoal > 0 {
            if projectedTotal >= yearlyGoal {
                insights.append(GivingInsight(
                    title: "On Track to Meet Goal",
                    description: "You're projected to meet or exceed your yearly goal of $\(String(format: "%.2f", yearlyGoal))!",
                    type: .achievement,
                    iconName: "checkmark.circle.fill"
                ))
            } else {
                let percentageOfGoal = projectedTotal / yearlyGoal * 100
                insights.append(GivingInsight(
                    title: "Year-End Goal Projection",
                    description: "You're on track to reach \(Int(percentageOfGoal))% of your yearly goal. Consider giving $\(String(format: "%.2f", suggestedMonthlyAmount)) monthly to finish strong.",
                    type: .suggestion,
                    iconName: "chart.line.uptrend.xyaxis"
                ))
            }
        }
    }
}

// MARK: - SmartInsightsView
/// Smart Giving Insights provides personalized guidance for your giving journey:
///
/// - **Giving Patterns**: Identifies your giving habits and consistency
/// - **Category Balance**: Offers suggestions for balanced giving across different categories
/// - **Year-End Projections**: Helps you "complete the year strong" with goal projections
/// - **Achievement Recognition**: Celebrates meaningful milestones in your giving journey
///
/// This view analyzes your giving history, category preferences, and goals to provide
/// actionable insights that help you make the most impact with your giving.
struct SmartInsightsView: View {
    @ObservedObject var insightsManager: InsightsManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Smart Giving Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Year-end projection section
                    if let projection = insightsManager.yearEndProjection {
                        YearEndProjectionView(projection: projection)
                            .padding(.horizontal)
                    }
                    
                    // Insights section
                    if !insightsManager.insights.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Giving Insights")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(insightsManager.insights) { insight in
                                InsightCardView(insight: insight)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        Text("Add more giving records to generate personalized insights.")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Category balance suggestions
                    if !insightsManager.categorySuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category Balance Suggestions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(insightsManager.categorySuggestions) { suggestion in
                                CategorySuggestionView(suggestion: suggestion)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Smart Insights")
        }
    }
}

// MARK: - Supporting Views for Insights
struct InsightCardView: View {
    let insight: InsightsManager.GivingInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: insight.iconName)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.title)
                    .font(.headline)
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var backgroundColor: Color {
        switch insight.type {
        case .achievement:
            return Color.green.opacity(0.2)
        case .pattern:
            return Color.blue.opacity(0.2)
        case .suggestion:
            return Color.orange.opacity(0.2)
        }
    }
    
    private var iconColor: Color {
        switch insight.type {
        case .achievement:
            return .green
        case .pattern:
            return .blue
        case .suggestion:
            return .orange
        }
    }
}

struct CategorySuggestionView: View {
    let suggestion: InsightsManager.CategorySuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(suggestion.color)
                    .frame(width: 12, height: 12)
                
                Text(suggestion.categoryName)
                    .font(.headline)
                    .foregroundColor(suggestion.color)
                
                Spacer()
                
                Text("\(Int(suggestion.currentPercentage))% → \(Int(suggestion.suggestedPercentage))%")
                    .font(.subheadline)
            }
            
            Text(suggestion.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            ProgressView(value: suggestion.currentPercentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: suggestion.color))
                .overlay(
                    GeometryReader { geometry in
                        Rectangle()
                            .stroke(suggestion.color, style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(width: 1)
                            .position(x: CGFloat(suggestion.suggestedPercentage) / 100 * geometry.size.width, y: geometry.size.height / 2)
                    }
                )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct YearEndProjectionView: View {
    let projection: InsightsManager.YearEndProjection
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Year-End Projection")
                    .font(.headline)
                
                Spacer()
                
                if projection.goalAmount > 0 {
                    Text("\(Int(projection.percentToGoal * 100))% of Goal")
                        .font(.subheadline)
                        .foregroundColor(projection.isOnTrack ? .green : .orange)
                }
            }
            
            if projection.goalAmount > 0 {
                VStack(spacing: 8) {
                    ProgressBar(value: projection.percentToGoal, color: projection.isOnTrack ? .green : .orange)
                        .frame(height: 12)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", projection.currentTotal))
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("Projected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", projection.projectedTotal))
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", projection.goalAmount))
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: projection.isOnTrack ? "checkmark.circle.fill" : "arrow.up.forward.circle.fill")
                        .foregroundColor(projection.isOnTrack ? .green : .orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if projection.isOnTrack {
                            Text("You're on track to meet your yearly goal!")
                                .font(.subheadline)
                        } else {
                            Text("Complete the Year Strong")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if projection.monthsRemaining > 0 {
                                Text("To reach your goal, consider giving $\(String(format: "%.2f", projection.suggestedMonthlyAmount)) monthly for the remaining \(projection.monthsRemaining) months.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - ReminderPreferences
struct ReminderPreferences: Codable, Equatable {
    var isEnabled: Bool = false
    var frequency: ReminderFrequency = .monthly
    var dayOfWeek: Int = 5 // Friday
    var dayOfMonth: Int = 15 // 15th
    var hour: Int = 9 // 9 AM
    var minute: Int = 0 // 00
    var lastNotificationDate: Date?
    
    enum ReminderFrequency: String, Codable, CaseIterable {
        case weekly = "Weekly"
        case biWeekly = "Bi-Weekly"
        case monthly = "Monthly"
        case custom = "Custom"
        
        var description: String {
            switch self {
            case .weekly: return "Every week"
            case .biWeekly: return "Every two weeks"
            case .monthly: return "Monthly"
            case .custom: return "Custom schedule"
            }
        }
    }
    
    static func == (lhs: ReminderPreferences, rhs: ReminderPreferences) -> Bool {
        return lhs.isEnabled == rhs.isEnabled &&
               lhs.frequency == rhs.frequency &&
               lhs.dayOfWeek == rhs.dayOfWeek &&
               lhs.dayOfMonth == rhs.dayOfMonth &&
               lhs.hour == rhs.hour &&
               lhs.minute == rhs.minute
    }
}

// MARK: - ReminderManager
class ReminderManager: ObservableObject {
    @Published var preferences: ReminderPreferences
    private let preferencesKey = "reminderPreferences"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(ReminderPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = ReminderPreferences()
        }
    }
    
    func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }
    
    // Format the next reminder time for display
    func formattedNextReminder() -> String {
        guard preferences.isEnabled else {
            return "No reminders scheduled"
        }
        
        let nextDate = calculateNextReminderDate()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return "Next reminder: \(formatter.string(from: nextDate))"
    }
    
    // Calculate when the next reminder would occur
    func calculateNextReminderDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = DateComponents()
        components.hour = preferences.hour
        components.minute = preferences.minute
        
        switch preferences.frequency {
        case .weekly:
            components.weekday = preferences.dayOfWeek + 1 // Calendar uses 1-7 for weekdays
            let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
            return nextDate
            
        case .biWeekly:
            components.weekday = preferences.dayOfWeek + 1
            var nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
            
            // If there's a last notification date and it's less than a week ago,
            // we need to add another week to get to the next bi-weekly date
            if let lastDate = preferences.lastNotificationDate {
                let daysSinceLastNotification = calendar.dateComponents([.day], from: lastDate, to: now).day ?? 0
                if daysSinceLastNotification < 10 { // About a week and a half
                    nextDate = calendar.date(byAdding: .day, value: 7, to: nextDate)!
                }
            }
            
            return nextDate
            
        case .monthly:
            components.day = min(preferences.dayOfMonth, calendar.range(of: .day, in: .month, for: now)?.count ?? 28)
            let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
            return nextDate
            
        case .custom:
            // Just default to next weekly for custom, which would be configured elsewhere
            components.weekday = preferences.dayOfWeek + 1
            let nextDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime)!
            return nextDate
        }
    }
    
    // Get the weekday name for a given index
    func weekdayName(for index: Int) -> String {
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return weekdays[index]
    }
    
    // Format the hour for display (12-hour format)
    func formattedHour(_ hour: Int) -> String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        let amPm = hour < 12 ? "AM" : "PM"
        return "\(displayHour):00 \(amPm)"
    }
    
    // Schedule a local notification based on the next reminder date
    func scheduleNotification() {
        #if os(iOS)
        // Request permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.createNotification()
            }
        }
        #endif
    }
    
    // Create a simple notification - NOT actually registering it with the system
    // Just a simulation for the app mockup
    private func createNotification() {
        #if os(iOS)
        let nextDate = calculateNextReminderDate()
        
        // Simple message based on frequency
        var message = "It's time for your "
        switch preferences.frequency {
        case .weekly: message += "weekly giving."
        case .biWeekly: message += "bi-weekly giving."
        case .monthly: message += "monthly giving."
        case .custom: message += "scheduled giving."
        }
        
        // Create content for notification (this is just simulation)
        _ = UNMutableNotificationContent()
        preferences.lastNotificationDate = Date()
        savePreferences()
        
        // Log in console for simulation purposes
        print("Notification would be scheduled for: \(nextDate)")
        print("Message: \(message)")
        #endif
    }
}

// MARK: - ReminderSettingsView
struct ReminderSettingsView: View {
    @ObservedObject var reminderManager: ReminderManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyInfo = false
    
    // Local state to track preferences during editing
    @State private var isEnabled: Bool
    @State private var selectedFrequency: ReminderPreferences.ReminderFrequency
    @State private var selectedDayOfWeek: Int
    @State private var selectedDayOfMonth: Int
    @State private var selectedHour: Int
    
    init(reminderManager: ReminderManager) {
        self.reminderManager = reminderManager
        
        // Initialize state from existing preferences
        _isEnabled = State(initialValue: reminderManager.preferences.isEnabled)
        _selectedFrequency = State(initialValue: reminderManager.preferences.frequency)
        _selectedDayOfWeek = State(initialValue: reminderManager.preferences.dayOfWeek)
        _selectedDayOfMonth = State(initialValue: reminderManager.preferences.dayOfMonth)
        _selectedHour = State(initialValue: reminderManager.preferences.hour)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Enable Giving Reminders", isOn: $isEnabled)
                        .onChange(of: isEnabled) { newValue in
                            if newValue && !showingPrivacyInfo {
                                showingPrivacyInfo = true
                            }
                        }
                        .alert("About Giving Reminders", isPresented: $showingPrivacyInfo) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("Reminders are saved locally on your device and no data is sent to external servers. Your privacy is important to us.")
                        }
                } header: {
                    Text("Notification Settings")
                } footer: {
                    Text("Gentle reminders help you maintain a consistent giving schedule.")
                }
                
                if isEnabled {
                    Section {
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(ReminderPreferences.ReminderFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                        
                        if selectedFrequency == .weekly || selectedFrequency == .biWeekly {
                            Picker("Day of Week", selection: $selectedDayOfWeek) {
                                ForEach(0..<7) { index in
                                    Text(reminderManager.weekdayName(for: index)).tag(index)
                                }
                            }
                        }
                        
                        if selectedFrequency == .monthly {
                            Picker("Day of Month", selection: $selectedDayOfMonth) {
                                ForEach(1..<29) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                        }
                        
                        Picker("Time", selection: $selectedHour) {
                            ForEach(7..<22) { hour in
                                Text(reminderManager.formattedHour(hour)).tag(hour)
                            }
                        }
                    } header: {
                        Text("Schedule")
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            if isEnabled {
                                Text("Next Reminder")
                                    .font(.headline)
                                
                                Text(reminderManager.formattedNextReminder())
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Your Privacy")
                                .font(.headline)
                            
                            Text("Reminders are gentle notifications that appear only on your device. No data is collected or sent to external servers.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 6)
                    } header: {
                        Text("Information")
                    }
                }
            }
            .navigationTitle("Giving Reminders")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        reminderManager.preferences.isEnabled = isEnabled
        reminderManager.preferences.frequency = selectedFrequency
        reminderManager.preferences.dayOfWeek = selectedDayOfWeek
        reminderManager.preferences.dayOfMonth = selectedDayOfMonth
        reminderManager.preferences.hour = selectedHour
        
        reminderManager.savePreferences()
        
        // If enabled, simulate scheduling the reminder
        if isEnabled {
            let nextDate = reminderManager.calculateNextReminderDate()
            print("Reminder would be scheduled for: \(nextDate)")
        }
    }
}

// MARK: - ThemeManager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false
    @Published var isHapticEnabled: Bool = true
    @Published var accentColor: Color = .blue
    
    private init() {
        // Initialize with system settings
        #if os(iOS)
        isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        #endif
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
    
    func impactFeedback() {
        #if os(iOS)
        if isHapticEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        #endif
    }
}

// MARK: - TaxInformationView
struct TaxInformationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Tax Information")
                        .font(.title)
                        .padding(.bottom)
                    
                    Group {
                        Text("Charitable Contributions")
                            .font(.headline)
                        
                        Text("Your charitable contributions may be tax-deductible. Keep track of your donations throughout the year to help with tax preparation.")
                            .font(.body)
                        
                        Text("Important Notes")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• Keep all donation receipts")
                            Text("• Document the date and amount of each contribution")
                            Text("• Consult with a tax professional for specific advice")
                            Text("• Different countries have different tax laws")
                        }
                        .font(.body)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
