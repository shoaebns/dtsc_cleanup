import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct ContentView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @StateObject private var locationManager = LocationManager()
    @State private var isProfilePresented = false
    @State private var mapZoomLevel: Double = 2500
    @State private var bottomSheetOffset: CGFloat = 300
    @State private var isPostModalPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var isPostSuccessful = false
    private let bottomSheetMinHeight: CGFloat = 150
    private let bottomSheetMaxHeight: CGFloat = 500

    var body: some View {
        NavigationView {
            ZStack {
                // Map View
                MapView(cameraPosition: $cameraPosition, mapZoomLevel: $mapZoomLevel)
                
                VStack {
                    SearchBar(isProfilePresented: $isProfilePresented)
                    Spacer()
                    BottomSheetView(
                        offset: $bottomSheetOffset,
                        mapZoomLevel: $mapZoomLevel,
                        isPostModalPresented: $isPostModalPresented,
                        selectedImage: $selectedImage
                    )
                }
                
                ZoomControls(zoomIn: zoomIn, zoomOut: zoomOut)
            }
        }
        .sheet(isPresented: $isPostModalPresented) {
            PostModalView(
                selectedImage: $selectedImage,
                isPresented: $isPostModalPresented
            )
        }
    }
    
    private func updateCameraPosition() {
        let dtscLocation = CLLocationCoordinate2D(latitude: 33.7812, longitude: -118.1892) // Long Beach DTSC location
        cameraPosition = .camera(MapCamera(centerCoordinate: dtscLocation, distance: mapZoomLevel))
    }
    
    private func zoomIn() {
        if mapZoomLevel > 1000 {
            mapZoomLevel -= 500
            updateCameraPosition()
        }
    }
    
    private func zoomOut() {
        if mapZoomLevel < 10000 {
            mapZoomLevel += 500
            updateCameraPosition()
        }
    }
}

struct MapView: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var mapZoomLevel: Double
    
    let dtscLocation = CLLocationCoordinate2D(latitude: 33.7812, longitude: -118.1892) // Long Beach DTSC location

    var body: some View {
        Map(position: $cameraPosition) {
            Annotation("", coordinate: dtscLocation, anchor: .center) {
                ZStack {
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 24, height: 24)
                    Circle().fill(Color.blue).frame(width: 16, height: 16)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            cameraPosition = .camera(MapCamera(centerCoordinate: dtscLocation, distance: mapZoomLevel))
        }
    }
}

struct SearchBar: View {
    @Binding var isProfilePresented: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.gray)
            Text("Search Location").foregroundColor(.gray).padding(.leading, 5)
            Spacer()
            Button(action: { isProfilePresented = true }) {
                Circle().fill(Color.red.opacity(0.3)).frame(width: 32, height: 32)
                    .overlay(Text("AA").font(.caption).foregroundColor(.black))
            }
            .sheet(isPresented: $isProfilePresented) { ProfileView() }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

struct BottomSheetView: View {
    @Binding var offset: CGFloat
    @Binding var mapZoomLevel: Double
    @Binding var isPostModalPresented: Bool
    @Binding var selectedImage: UIImage?

    let minHeight: CGFloat = 150
    let maxHeight: CGFloat = 500

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.gray).frame(width: 40, height: 6).padding(.top, 8)

            NavigationLink(destination: TaskDescriptionView()) {
                            TaskRowView() // Removed clock icon here
                        }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)

            FavoritesRowView(
                isPostModalPresented: $isPostModalPresented,
                selectedImage: $selectedImage
            )
            
            Spacer()
        }
        .padding(.horizontal)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.9)))
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    let newOffset = offset + gesture.translation.height
                    if newOffset > minHeight && newOffset < maxHeight {
                        offset = newOffset
                    }
                }
                .onEnded { _ in
                    offset = offset < (minHeight + maxHeight) / 2 ? minHeight : maxHeight
                }
        )
        .animation(.spring(), value: offset)
    }
}

struct FavoritesRowView: View {
    @Binding var isPostModalPresented: Bool
    @Binding var selectedImage: UIImage?

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            NavigationLink(destination: ClockView()) { IconLabelView(icon: "clock.fill", label: "Clock") }
            NavigationLink(destination: ReportIssueView()) { IconLabelView(icon: "exclamationmark.bubble.fill", label: "Report an Issue") }
            Button(action: {
                isPostModalPresented = true
            }) {
                IconLabelView(icon: "photo.fill", label: "Post")
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct PostModalView: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @State private var isPickerPresented = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isPostSuccessful = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                } else {
                    Text("No image selected")
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        pickerSource = .camera
                        isPickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Camera")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }

                    Button(action: {
                        pickerSource = .photoLibrary
                        isPickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                            Text("Gallery")
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    isPostSuccessful = true
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .font(.title2)
                        Text("Post")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                .padding(.horizontal)

                if isPostSuccessful {
                    Text("Post Successful!")
                        .foregroundColor(.green)
                        .font(.headline)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Post")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title)
                    }
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                ImagePicker(sourceType: pickerSource, selectedImage: $selectedImage)
            }
        }
    }
}


struct IconLabelView: View {
    var icon: String
    var label: String
    
    var body: some View {
        VStack {
            Image(systemName: icon).foregroundColor(.blue).padding(10).background(Circle().fill(Color.gray.opacity(0.2)))
            Text(label).font(.caption)
        }
    }
}

struct TaskRowView: View {
    var body: some View {
        HStack {
            Image(systemName: "briefcase.fill").foregroundColor(.blue).padding(10).background(Circle().fill(Color.gray.opacity(0.2)))
            VStack(alignment: .leading) {
                Text("Task").font(.headline).foregroundColor(.primary)
                Text("Task description").font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct TaskDescriptionView: View {
    // Sample tasks for the app with statuses
    let tasks: [String: [Tasks]] = [
        "2024-12-10": [
            Tasks(
                title: ["en": "Prepare Equipment", "es": "Preparar el equipo"],
                time: "8:00 AM",
                description: ["en": "Ensure all equipment is ready for the day's inspections.",
                              "es": "Asegúrese de que todo el equipo esté listo para las inspecciones del día."],
                status: "finished"
            ),
            Tasks(
                title: ["en": "Morning Briefing", "es": "Reunión matutina"],
                time: "9:00 AM",
                description: ["en": "Discuss the day's tasks and assignments.",
                              "es": "Discutir las tareas y asignaciones del día."],
                status: "finished"
            )
        ],
        "2024-12-11": [
            Tasks(
                title: ["en": "Inspect Hazardous Waste Site", "es": "Inspeccionar el sitio de residuos peligrosos"],
                time: "9:00 AM",
                description: ["en": "Conduct a thorough inspection of the hazardous waste site to ensure compliance with federal and state regulations. Verify containment measures and document any violations.",
                              "es": "Realice una inspección exhaustiva del sitio de residuos peligrosos para garantizar el cumplimiento de las normativas federales y estatales. Verifique las medidas de contención y documente cualquier infracción."],
                status: "stopped"
            ),
            Tasks(
                title: ["en": "Review Compliance Reports", "es": "Revisar informes de cumplimiento"],
                time: "1:30 PM",
                description: ["en": "Analyze reports submitted by facilities.",
                              "es": "Analizar los informes presentados por las instalaciones."],
                status: "not_done"
            )
        ],
        "2024-12-12": [
            Tasks(
                title: ["en": "Site Evacuation Drill", "es": "Simulacro de evacuación del sitio"],
                time: "10:00 AM",
                description: ["en": "Conduct an evacuation drill and document any issues.",
                              "es": "Realice un simulacro de evacuación y documente cualquier problema."],
                status: "future"
            )
        ],
        "2024-12-17": [
            Tasks(
                title: ["en": "Community Meeting", "es": "Reunión comunitaria"],
                time: "10:00 AM",
                description: ["en": "Discuss environmental safety with the local community.",
                              "es": "Discutir la seguridad ambiental con la comunidad local."],
                status: "future"
            ),
            Tasks(
                title: ["en": "Safety Training", "es": "Capacitación en seguridad"],
                time: "3:00 PM",
                description: ["en": "Conduct training on handling hazardous materials.",
                              "es": "Realizar capacitación sobre el manejo de materiales peligrosos."],
                status: "future"
            )
        ]
    ]

    @State private var selectedDate: String = "2024-12-12" // Default selected date
    @State private var language: String = "en" // Default language (English)

    var body: some View {
        VStack(spacing: 16) {
            // Horizontal Date Picker
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { scrollProxy in
                    HStack(spacing: 16) {
                        ForEach(generateDatesForMonth(year: 2024, month: 12), id: \.self) { date in
                            VStack {
                                Text(formattedDay(date)) // Day (e.g., 12)
                                    .font(.headline)
                                Text(formattedWeekday(date)) // Weekday (e.g., Tue)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(selectedDate == date ? Color.blue : Color.gray.opacity(tasks[date] != nil ? 0.5 : 0.3))
                            .foregroundColor(selectedDate == date ? .white : (tasks[date] != nil ? .black : .gray))
                            .clipShape(Capsule())
                            .id(date)
                            .onTapGesture {
                                selectedDate = date
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        scrollProxy.scrollTo(selectedDate, anchor: .center)
                    }
                }
            }
            
            // Task List for Selected Date
            ScrollView {
                VStack(spacing: 16) {
                    if let tasksForDate = tasks[selectedDate] {
                        ForEach(tasksForDate, id: \.title) { task in
                            TaskCardView(task: task, language: language)
                        }
                    } else {
                        Text(language == "en" ? "No tasks available for this date." : "No hay tareas disponibles para esta fecha.")
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
            
            // Language Dropdown
            HStack {
                Spacer()
                Picker("Language", selection: $language) {
                    Text("English").tag("en")
                    Text("Español").tag("es")
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.trailing)
            }
        }
        .padding()
        .navigationTitle(language == "en" ? "Task Details" : "Detalles de tareas")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDay(_ date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateObj = formatter.date(from: date) {
            formatter.dateFormat = "dd"
            return formatter.string(from: dateObj)
        }
        return date
    }
    
    private func formattedWeekday(_ date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateObj = formatter.date(from: date) {
            formatter.dateFormat = "E"
            return formatter.string(from: dateObj)
        }
        return date
    }
    
    private func generateDatesForMonth(year: Int, month: Int) -> [String] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: startDate) else {
            return []
        }
        return range.compactMap { day -> String? in
            let components = DateComponents(year: year, month: month, day: day)
            if let date = calendar.date(from: components) {
                return dateFormatter.string(from: date)
            }
            return nil
        }
    }
}

// TaskCardView for displaying individual tasks with status color coding
struct TaskCardView: View {
    let task: Tasks
    let language: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title[language] ?? "")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            Text(task.time)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
            Text(task.description[language] ?? "")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(width: 400) // Fixed size for the card
        .background(getCardColor(for: task.status))
        .cornerRadius(10)
    }

    // Helper function to get color based on status
    private func getCardColor(for status: String) -> Color {
        switch status {
        case "finished":
            return Color.green.opacity(0.8)
        case "not_done":
            return Color.red.opacity(0.8)
        case "stopped":
            return Color.orange.opacity(0.8)
        case "future":
            return Color.blue.opacity(0.8)
        default:
            return Color.gray.opacity(0.8)
        }
    }
}

// Updated Tasks model to include a status
struct Tasks {
    let title: [String: String]
    let time: String
    let description: [String: String]
    let status: String
}
struct TaskDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        TaskDescriptionView()
    }
}
struct ReportIssueView: View {
    @State private var text = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showSuccessMessage = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Issue")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding(.bottom, 16)

                TextEditor(text: $text)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                    .frame(height: 200)

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(10)
                        .padding(.bottom, 16)
                }

                Button(action: {
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.title2)
                        Text("Attach Image")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    showSuccessMessage = true
                }) {
                    Text("Report")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
            }
            .alert(isPresented: $showSuccessMessage) {
                Alert(
                    title: Text("Success"),
                    message: Text("Reporting Issue Successful"),
                    dismissButton: .default(Text("OK"), action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                )
            }
        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.first {
            DispatchQueue.main.async { self.location = newLocation }
            manager.stopUpdatingLocation()
        }
    }
}

struct ZoomControls: View {
    let zoomIn: () -> Void
    let zoomOut: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: zoomIn) {
                Image(systemName: "plus").foregroundColor(.black).padding().background(Color.gray.opacity(0.2)).clipShape(Circle())
            }
            Button(action: zoomOut) {
                Image(systemName: "minus").foregroundColor(.black).padding().background(Color.gray.opacity(0.2)).clipShape(Circle())
            }
        }
        .padding(.trailing, 16)
        .padding(.top, 90)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}
struct ClockView: View {
    // Sample tasks for DTSC workers
    let tasks: [String: [Task]] = [
        "2024-12-10": [
            Task(title: "Prepare Equipment", time: "9:00 AM"),
            Task(title: "Morning Briefing", time: "1:30 PM")
        ],
        "2024-12-11": [
            Task(title: "Inspect Hazardous Waste Site", time: "10:00 AM"),
            Task(title: "Review Compliance Reports", time: "3:00 PM")
        ],
        "2024-12-12": [
            Task(title: "Site Evacuation Drill", time: "9:00 AM"),
        ],
        "2024-12-17": [
            Task(title: "Community Meeting", time: "10:00 AM"),
            Task(title: "Safety Training", time: "3:00 PM")
        ],
    ]

    @State private var selectedDate = Date() // Default to today's date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 16) {
            // Calendar View
            VStack {
                Text("Select a Date")
                    .font(.title2)
                    .fontWeight(.bold)
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }

            // Task List for Selected Date
            VStack(alignment: .leading) {
                Text("Tasks for \(formattedDate(selectedDate))")
                    .font(.headline)
                    .padding(.bottom, 10)

                ScrollView {
                    VStack(spacing: 12) {
                        let selectedDateString = dateFormatter.string(from: selectedDate)
                        if let tasksForDate = tasks[selectedDateString] {
                            ForEach(tasksForDate, id: \.title) { task in
                                HStack {
                                    Text(task.title)
                                        .font(.body)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text(task.time)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(10)
                            }
                        } else {
                            Text("No tasks for this date.")
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .padding()
        .background(Color(.systemGray6).ignoresSafeArea())
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct Task {
    let title: String
    let time: String
}

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        ClockView()
    }
}
struct ProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, Sondos! 😊") // Greeting Text
                .font(.title)
                .fontWeight(.bold)
            
            // Profile Image
            Image(systemName: "person.crop.circle.fill") // Using SF Symbol for an avatar placeholder
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .foregroundColor(.blue)
                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
            
            Text("Welcome to Your Profile")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Divider().padding(.horizontal)
            
            // Account Information Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Account Information:")
                    .font(.headline)
                
                NavigationLink(destination: Text("Edit Profile")) {
                    HStack {
                        Text("Edit Your Profile")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 1)
                }
                
                HStack {
                    Text("Name: Sondos Al-Amri")
                    Spacer()
                    Image(systemName: "person.fill")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)
                
                HStack {
                    Text("Email: sondos@example.com")
                    Spacer()
                    Image(systemName: "envelope.fill")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)
            }
            .padding(.horizontal)
            
            Divider().padding(.horizontal)
            
            // Profile Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Profile:")
                    .font(.headline)
                
                HStack {
                    Text("Designation")
                    Spacer()
                    Text("Field Worker")
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)
                
               
                
                NavigationLink(destination: Text("Help")) {
                    HStack {
                        Text("Help")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 1)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
