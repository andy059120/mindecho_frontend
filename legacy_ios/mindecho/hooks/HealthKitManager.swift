import Foundation
import HealthKit
import SwiftUI

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var hrvMs: Double?
    @Published var sleepHours: Double?
    @Published var steps: Double?
    @Published var weightKg: Double?
    @Published var errorMessage: String?
    
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    func refresh() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "Health data unavailable"
            return
        }
        
        requestAuthorization { [weak self] granted in
            guard let self, granted else {
                DispatchQueue.main.async {
                    self?.errorMessage = "Health access denied"
                    self?.clearMetrics()
                }
                return
            }
            
            self.fetchLatestHRV()
            self.fetchSleepQuality()
            self.fetchSteps()
            self.fetchLatestWeight()
        }
    }
    
    #if DEBUG
    func loadMockData() {
        hrvMs = 52
        sleepHours = 2.8
        steps = 8420
        weightKg = 54.3
        errorMessage = nil
    }
    #endif
    
    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis),
              let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(false)
            return
        }
        
        let readTypes: Set<HKObjectType> = [hrvType, sleepType, stepsType, weightType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { granted, _ in
            completion(granted)
        }
    }
    
    private func fetchLatestHRV() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let value = (samples?.first as? HKQuantitySample)?
                .quantity
                .doubleValue(for: .secondUnit(with: .milli))
            DispatchQueue.main.async {
                self?.hrvMs = value
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestWeight() {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let value = (samples?.first as? HKQuantitySample)?
                .quantity
                .doubleValue(for: .gramUnit(with: .kilo))
            DispatchQueue.main.async {
                self?.weightKg = value
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSteps() {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, _ in
            let value = stats?.sumQuantity()?.doubleValue(for: .count())
            DispatchQueue.main.async {
                self?.steps = value
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleepQuality() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let deepValue = HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            let deepSeconds = samples?
                .compactMap { $0 as? HKCategorySample }
                .filter { $0.value == deepValue }
                .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            
            DispatchQueue.main.async {
                self?.sleepHours = deepSeconds != nil ? (deepSeconds! / 3600.0) : nil
            }
        }
        
        healthStore.execute(query)
    }
    
    private func clearMetrics() {
        hrvMs = nil
        sleepHours = nil
        steps = nil
        weightKg = nil
    }
}
