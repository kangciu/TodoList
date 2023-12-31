//
//  Home.swift
//  TodoList
//
//  Created by 강치우 on 11/11/23.
//

import SwiftUI

struct Home: View {
    // 투두리스트 Properties
    @State private var currentDate: Date = .init()
    @State private var weekSlider: [[Date.WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false
    @State private var createNewTask: Bool = false
    // Animation Namespace
    @Namespace private var animation
    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: {
            // Header View
            HeaderView()
            
            ScrollView(.vertical) {
                VStack {
                    // Tasks View
                    TasksView(currentDate: $currentDate)
                }
                .hSpacing(.center)
                .vSpacing(.center)
            }
            .scrollIndicators(.hidden)
        })
        .vSpacing(.top)
        .overlay(alignment: .bottomTrailing) {
            Button(action: {
                createNewTask.toggle()
            }, label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 55, height: 55)
                    .background(.darkblue.shadow(.drop(color: .black.opacity(0.25), radius: 5, x: 10, y: 10)), in: .circle)
            })
            .padding(15)
        }
        .onAppear(perform: {
            if weekSlider.isEmpty {
                let currentWeek = Date().fetchWeek()
                
                if let firstDate = currentWeek.first?.date {
                    weekSlider.append(firstDate.createPreviousWeek())
                }
                
                weekSlider.append(currentWeek)
                
                if let lastDate = currentWeek.last?.date {
                    weekSlider.append(lastDate.createNextWeek())
                }
            }
        })
        .sheet(isPresented: $createNewTask, content: {
            NewTaskView()
                .presentationDetents([.height(300)]) // 시트 높이
                .interactiveDismissDisabled() // 시트 안닫히네?
                .presentationCornerRadius(30) // 시트 라인
                .presentationBackground(Color(.systemGray6))
        })
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        VStack(alignment: .leading, spacing: 6, content: {
            HStack(spacing: 5) {
                Text(currentDate.format("MM월"))
                    .foregroundStyle(.darkblue)
                
                Text(currentDate.format("YYYY"))
                    .foregroundStyle(.gray)
            }
            .font(.title.bold())
            
            Text(currentDate.formatted(date: .complete, time: .omitted))
                .font(.callout)
                .fontWeight(.semibold)
                .textScale(.secondary)
                .foregroundStyle(.gray)
            
            // Week Slider
            TabView(selection: $currentWeekIndex) {
                ForEach(weekSlider.indices, id: \.self) { index in
                    let week = weekSlider[index]
                    WeekView(week)
                        .padding(.horizontal, 15)
                        .tag(index)
                }
            }
            .padding(.horizontal, -15)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 90)
        })
        .hSpacing(.leading)
        .overlay(alignment: .topTrailing, content: {
            Button(action: {}, label: {
                Image(.picture)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .clipShape(.circle)
            })
        })
        .padding(15)
        .background(.white)
        .onChange(of: currentWeekIndex, initial: false) { oldValue, newValue in
            // Creating When it reaches first/last Page
            if newValue == 0 || newValue == (weekSlider.count - 1) {
                createWeek = true
            }
        }
    }
    
    // Weak View
    @ViewBuilder
    func WeekView(_ week: [Date.WeekDay]) -> some View {
        HStack(spacing: 0) {
            ForEach(week) { day in
                VStack(spacing: 8) {
                    Text(day.date.format("E"))
                        .font(.callout)
                        .fontWeight(.medium)
                        .textScale(.secondary)
                        .foregroundStyle(.gray)
                    
                    Text(day.date.format("dd"))
                        .font(.callout)
                        .fontWeight(.bold)
                        .textScale(.secondary)
                        .foregroundStyle(isSameDate(day.date, currentDate) ? .white : .gray)
                        .frame(width: 35, height: 35)
                        .background(content: {
                            if isSameDate(day.date, currentDate) {
                                Circle()
                                    .fill(.darkblue)
                                    .matchedGeometryEffect(id: "TABINDICATOR", in: animation)
                            }
                            
                            // 오늘 날짜를 표시해줌
                            if day.date.isToday {
                                Circle()
                                    .fill(.cyan)
                                    .frame(width: 5, height: 5)
                                    .vSpacing(.bottom)
                                    .offset(y: 12)
                            }
                        })
                        .background(.white.shadow(.drop(radius: 1)), in: .circle)
                        // 프레임 주고 백그라운드에 쉐도우 활용해서 테두리 주는 법
                }
                .hSpacing(.center)
                .contentShape(.rect)
                .onTapGesture {
                    // Updating Current Date
                    withAnimation(.snappy) {
                        currentDate = day.date
                    }
                }
            }
        }
        .background {
            GeometryReader {
                let minX = $0.frame(in: .global).minX
                
                Color.clear
                    .preference(key: OffsetKey.self, value: minX)
                    .onPreferenceChange(OffsetKey.self) { value in
                        // When the Offset reaches 15 and if the createWeek is toggled then simply generating net set of week
                        if value.rounded() == 15 && createWeek {
                            paginateWeek()
                            createWeek = false
                        }
                    }
            }
        }
    }
    // 페이지 넘길 때마다 자동 날짜 변경
    func paginateWeek() {
        // 안전한지 확인
        if weekSlider.indices.contains(currentWeekIndex) {
            if let firstDate = weekSlider[currentWeekIndex].first?.date, currentWeekIndex == 0 {
                // 0번째 인덱스에서 새 주 삽입 및 마지막 배열 항목 제거
                weekSlider.insert(firstDate.createPreviousWeek(), at: 0)
                weekSlider.removeLast()
                currentWeekIndex = 1
            }
            
            if let lastDate = weekSlider[currentWeekIndex].last?.date, currentWeekIndex == (weekSlider.count - 1) {
                // 마지막 인덱스에서 새 주 추가 및 첫 번째 배열 항목 제거
                weekSlider.append(lastDate.createNextWeek())
                weekSlider.removeFirst()
                currentWeekIndex = weekSlider.count - 2
            }
        }
    }
}

#Preview {
    ContentView()
}
