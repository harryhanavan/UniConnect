import '../../shared/models/user.dart';
import '../../shared/models/society.dart';
import '../../shared/models/event.dart';
import '../../shared/models/friend_request.dart';
import '../../shared/models/location.dart';
import '../../shared/models/privacy_settings.dart';
import '../utils/performance_monitor.dart';
import 'demo_data_loader.dart';

class DemoDataManager {
  static DemoDataManager? _instance;
  static DemoDataManager get instance => _instance ??= DemoDataManager._();
  DemoDataManager._();

  // Current logged in user - cached for performance
  User? _currentUser;
  User get currentUser {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return _currentUser ??= users.first;
  }
  
  Future<User> get currentUserAsync async {
    await _initializeData();
    return _currentUser ??= users.first;
  }
  
  // Lazy-loaded data collections
  List<PrivacySettings>? _privacySettings;
  List<Location>? _locations;
  List<FriendRequest>? _friendRequests;
  List<User>? _users;
  List<Event>? _events;
  List<Society>? _societies;
  
  // Flag to track if data is loaded from JSON
  bool _isInitialized = false;

  // Initialize all data from JSON files
  Future<void> _initializeData() async {
    if (_isInitialized) return;
    
    _users = await DemoDataLoader.loadUsers();
    _societies = await DemoDataLoader.loadSocieties();
    _events = await DemoDataLoader.loadEvents();
    _locations = await DemoDataLoader.loadLocations();
    _privacySettings = await DemoDataLoader.loadPrivacySettings();
    _friendRequests = await DemoDataLoader.loadFriendRequests();
    
    // Validate data integrity
    final warnings = await DemoDataLoader.validateDataIntegrity(
      users: _users!,
      privacySettings: _privacySettings!,
      friendRequests: _friendRequests!,
      events: _events!,
      societies: _societies!,
      locations: _locations!,
    );
    
    if (warnings.isNotEmpty) {
      print('Demo data integrity warnings:');
      for (final warning in warnings) {
        print('  - $warning');
      }
    }
    
    _isInitialized = true;
  }
  
  
    Society(
      id: 'soc_001',
      name: 'User Experience & Interaction Design Society (UXIDSoc)',
      description: 'UXID Society is a student-run community for the interaction designers of tomorrow aiming to help students ideate, cooperate and network!',
      aboutUs: 'We have a dream to assist those who are undertaking interaction design degrees or those who are interested in the interaction design field, we call these people tomorrows\' designers! Through our experiences, we know that working on constantly improving and enhancing oneself as a designer can prove to be difficult, therefore, we would like to provide some support.\n\nAt UXID (User Experience & Interaction Design) Society, we\'ve previously hosted the relaxing free donut day to raise awareness about our society, which was a big hit during the exhausting exam preparation week. Looking towards semesters ahead, you (the potential, amazing, talented member) can expect a wide range of social and industry events. We\'re currently working with amazing industry professionals within the university to give you awesome opportunities, like the up and coming "Transitioning from Uni to Real-World in UX/UI" panel featuring UTS Alumni, workshops, and a unique opportunity that you might\'ve never seen coming but really, REALLY, want to happen; ProjectUX, a 8-week program held every semester where you can work in groups to solve a design problem provided by an ACTUAL client and supervised by a industry professional as your mentor. New to design? No worries, three workshops will help build your skills! Industry events aside (though they are already very captivating), We\'re also planning fun socials like themed game nights, movies, karaoke, and "bad design" competitions with prizes, plus a dedicated Discord server to help you connect with like minded peers.\n\nHop on in and join UXID Society today. Whether you want to go all-in and join ProjectUX or if you just want to chill and casually enhance your skills and socialise, we\'ll be here cheering you on!',
      category: 'Technology',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2025/07/UXID-LOGO-312x312-1.png',
      memberCount: 285,
      tags: ['UX/UI', 'Design', 'Interaction Design', 'ProjectUX', 'Workshops'],
      isJoined: true,
      adminIds: ['user_002'],
    ),
    Society(
      id: 'soc_002',
      name: 'UTS Programmers Society (ProgSoc)',
      description: 'ProgSoc is UTS\'s largest technology society, bringing together students passionate about programming, software development, and technology innovation. We host regular events including hackathons, coding workshops, industry networking sessions, and collaborative projects. Whether you\'re a beginner or experienced developer, ProgSoc offers opportunities to learn, build, and connect with like-minded individuals in the tech industry.',
      aboutUs: 'Welcome to ProgSoc - where code meets community! We are UTS\'s premier technology society with over 580 members passionate about all things programming. Our mission is to bridge the gap between academic learning and real-world software development through hands-on experiences and industry connections.\n\nOur flagship events include the annual ProgSoc Hackathon (with prizes worth over \$10,000), weekly coding workshops covering everything from web development to machine learning, monthly industry talks featuring developers from Google, Atlassian, and Canva, and collaborative open-source projects that make real impact.\n\nWhether you\'re struggling with your first \"Hello World\" or deploying production applications, ProgSoc has something for you. Join our vibrant Discord community, participate in coding competitions, get mentorship from senior students, and build your portfolio with real projects. Together, we debug, develop, and deploy!',
      category: 'Technology',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2022/01/Programmers-Society-Logo.png',
      memberCount: 580,
      tags: ['Programming', 'Hackathons', 'Tech Talks', 'Software Development', 'Networking'],
      isJoined: true,
      adminIds: ['user_003'],
    ),
    Society(
      id: 'soc_003',
      name: 'UTS Engineering Society',
      description: 'The Engineering Society at UTS serves all engineering disciplines, fostering collaboration and professional growth among students. We organize industry networking events, technical workshops, professional development seminars, and social gatherings. Our society bridges the gap between academic learning and industry practice, helping students build connections and develop skills essential for their engineering careers.',
      aboutUs: 'The UTS Engineering Society represents over 3,000 engineering students across all disciplines - from Civil and Mechanical to Software and Biomedical Engineering. Since 1988, we\'ve been the voice of engineering students at UTS, advocating for academic excellence and professional development.\n\nOur comprehensive program includes industry site visits to major infrastructure projects, professional skills workshops (resume writing, interview preparation, LinkedIn optimization), technical competitions including the annual Engineering Challenge, networking nights with industry partners, and social events that bring together students from all engineering streams.\n\nWe maintain strong partnerships with Engineers Australia, major engineering firms, and innovative startups, providing our members with exclusive internship opportunities, graduate program insights, and mentorship connections. Join us to transform from an engineering student into an industry-ready professional!',
      category: 'Academic',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2022/01/Engineering-Society-Logo.png',
      memberCount: 485,
      tags: ['Engineering', 'Professional Development', 'Industry', 'Technical', 'Networking'],
      isJoined: false,
      adminIds: ['user_004'],
    ),
    Society(
      id: 'soc_004',
      name: 'UTS Car Society',
      description: 'Car Society brings together automotive enthusiasts from across UTS to share their passion for cars, motorcycles, and all things automotive. We organize regular car meets, track days, technical workshops covering maintenance and modifications, and social events. Whether you\'re into JDM, European, American muscle, or electric vehicles, our diverse community welcomes all automotive interests and skill levels.',
      aboutUs: 'Rev up your university experience with UTS Car Society! We\'re a community of petrolheads, EV enthusiasts, and everyone in between who share a passion for all things automotive. From vintage classics to cutting-edge electric vehicles, if it has wheels, we\'re interested!\n\nOur action-packed calendar includes monthly Cars & Coffee meets in Sydney, track days at Eastern Creek and Wakefield Park, hands-on workshops covering basic maintenance to performance modifications, automotive photography sessions, go-karting competitions, and exclusive garage tours of private collections and workshops.\n\nWe welcome all skill levels - whether you\'re a seasoned mechanic or can\'t tell a spark plug from a glow plug. Our experienced members love sharing knowledge about engine building, suspension tuning, detailing techniques, and motorsport. Plus, we have special interest groups for JDM, Euro, muscle cars, motorcycles, and EVs. Join us and shift your uni life into high gear!',
      category: 'Automotive',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2022/01/Car-Society-Logo.png',
      memberCount: 195,
      tags: ['Cars', 'Automotive', 'Racing', 'Workshops', 'Car Meets'],
      isJoined: false,
      adminIds: ['user_005'],
    ),
    Society(
      id: 'soc_005',
      name: 'CIAO Society',
      description: 'Building bridges across cultures and supporting international students. Cultural events, social gatherings, and peer support networks.',
      aboutUs: 'CIAO (Culture, Inclusion, Acceptance, Opportunity) Society is your home away from home at UTS. We\'re dedicated to supporting international students and celebrating the rich cultural diversity of our university community. With members from over 50 countries, we create a welcoming space where every culture is celebrated and every voice is heard.\n\nOur support programs include arrival assistance for new international students, language exchange partnerships, academic support groups, visa and accommodation guidance, and mental health support sessions. We organize vibrant cultural festivals throughout the year including Lunar New Year celebrations, Diwali Festival of Lights, Harmony Day, International Food Fair, and monthly cultural showcases.\n\nBeyond events, we provide practical support through our buddy system, emergency assistance network, and career development workshops tailored for international students. Whether you\'re homesick, need help navigating Australian culture, or want to share your own culture with others, CIAO is here for you. Together, we make UTS feel like home!',
      category: 'Cultural',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2022/07/294144987_2211721325670245_4489648924956177878_n.jpg',
      memberCount: 420,
      tags: ['Cultural', 'International', 'Social', 'Support'],
      isJoined: true,
      adminIds: ['user_002'],
    ),
    Society(
      id: 'soc_006',
      name: 'UTS Law Students Society',
      description: 'Supporting law students through their academic journey. Mooting competitions, legal workshops, and networking with legal professionals.',
      aboutUs: 'The UTS Law Students\' Society (LSS) is the peak representative body for over 2,000 law students at UTS. We\'re committed to enhancing your legal education through practical experience, professional development, and building lasting connections within the legal community.\n\nOur comprehensive competition program includes internal and intervarsity mooting, client interviewing, witness examination, and negotiation competitions. We run the prestigious UTS Law Revue, publish the award-winning Poetic Justice law journal, and host the annual Law Ball - the highlight of the social calendar.\n\nProfessional development is at our core. We facilitate clerkship information sessions with top-tier firms, Criminal Law and Social Justice career panels, workshops on legal research and writing, networking events with the judiciary and bar, and mentoring programs connecting students with practicing lawyers. Our wellbeing initiatives ensure students maintain balance while navigating the demands of law school. Join LSS and transform from law student to legal professional!',
      category: 'Academic',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2022/01/Law-Students-Society-Logo.png',
      memberCount: 220,
      tags: ['Law', 'Mooting', 'Legal Workshops', 'Professional Development'],
      isJoined: false,
      adminIds: ['user_004'],
    ),
    Society(
      id: 'soc_007',
      name: 'UTS Hellenic Society',
      description: 'The Hellenic Society celebrates and promotes Greek culture, history, and traditions within the UTS community. We host cultural events including traditional Greek nights with music and dancing, educational workshops about Greek history and philosophy, networking events, and community service projects. Our society welcomes both Greek students and those interested in learning about Greek heritage and culture.',
      aboutUs: 'Καλώς ήρθατε! Welcome to the UTS Hellenic Society - your gateway to Greek culture, heritage, and community at university. For over 20 years, we\'ve been sharing the richness of Hellenic civilization with the UTS community, from ancient philosophy to modern Greek culture.\n\nOur cultural program brings Greece to Sydney through traditional Greek dance workshops and performances, Greek language conversation classes, cooking demonstrations featuring regional Greek cuisine, film screenings of classic and contemporary Greek cinema, celebrations of Greek Independence Day and Orthodox Easter, and philosophical discussions exploring Socrates, Plato, and Aristotle.\n\nWe maintain strong connections with the broader Greek-Australian community through partnerships with local Greek restaurants and businesses, volunteer work with Greek community organizations, and networking events with Greek-Australian professionals. Whether you\'re Greek, have Greek heritage, or simply love Greek culture, you\'ll find a warm welcome here. Join us for some mezze, music, and meaningful connections. Όπα!',
      category: 'Cultural',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2022/01/Hellenic-Logo.png',
      memberCount: 175,
      tags: ['Greek', 'Cultural', 'Heritage', 'Community', 'Networking'],
      isJoined: false,
      adminIds: ['user_003'],
    ),
    Society(
      id: 'soc_008',
      name: 'UTS Animation Guild',
      description: 'The Animation Guild is the creative hub for aspiring animators, digital artists, and storytellers at UTS. We provide workshops on 2D and 3D animation techniques, film screenings of classic and contemporary animated works, industry networking opportunities with professional animators and studios, and collaborative projects where members can work together on animated short films and creative endeavors.',
      aboutUs: 'Bring your imagination to life with the UTS Animation Guild! We\'re a collective of artists, animators, and storytellers pushing the boundaries of visual narrative. From hand-drawn 2D animation to cutting-edge 3D CGI, we explore every facet of the animation arts.\n\nOur hands-on workshop series covers character design and storyboarding, 2D animation in TVPaint and Toon Boom, 3D modeling and rigging in Maya and Blender, motion graphics in After Effects, and stop-motion techniques. We host regular animation film festivals showcasing student work, masterclasses with industry professionals from Pixar, Disney, and Animal Logic, and collaborative projects including our annual 48-hour animation challenge.\n\nMembers gain access to our animation lab with Wacom tablets and professional software, feedback sessions with experienced animators, internship opportunities at local studios, and a supportive community of fellow artists. Whether you dream of creating the next Studio Ghibli masterpiece or working on blockbuster VFX, the Animation Guild is where your journey begins!',
      category: 'Creative',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2022/01/Animation-Guild-Logo.png',
      memberCount: 255,
      tags: ['Animation', 'Digital Art', 'Creative', 'Film', 'Collaboration'],
      isJoined: true,
      adminIds: ['user_005'],
    ),
    Society(
      id: 'soc_009',
      name: 'UTS Dinner Society',
      description: 'Dinner Society brings UTS students together through shared love of food and dining experiences. We organize group restaurant visits to explore Sydney\'s diverse culinary scene, cooking workshops and masterclasses, food festivals and cultural food events, wine and cheese tastings, and themed dinner parties. Our society creates a welcoming social environment where students can make friends, discover new cuisines, and enjoy great food together.',
      aboutUs: 'Food brings people together, and at UTS Dinner Society, we\'re all about creating memorable dining experiences and lasting friendships. We believe the best conversations happen over good food, and Sydney\'s incredible culinary diversity is our playground!\n\nOur gastronomic adventures include weekly restaurant crawls exploring hidden gems and popular hotspots, monthly themed dinners (think Korean BBQ, Italian feast, Yum Cha sessions), cooking masterclasses with professional chefs, food market tours and festival visits, wine and cheese appreciation evenings, and our famous end-of-semester banquets.\n\nWe cater to all dietary requirements and budgets, with events ranging from cheap eats under \$15 to special occasion fine dining. Our members enjoy exclusive restaurant discounts, a supportive foodie community, cooking skill development, and cultural exploration through cuisine. Whether you\'re a MasterChef wannabe or can barely boil water, if you love food and good company, you belong here. Come hungry, leave happy!',
      category: 'Social',
      logoUrl: 'https://www.activateuts.com.au/wp-content/uploads/2023/12/Dinner-Society_Logo_Feb-2024.png',
      memberCount: 420,
      tags: ['Food', 'Social', 'Dining', 'Culinary', 'Restaurant'],
      isJoined: false,
      adminIds: ['user_004'],
    ),
  ];

  // Demo events - covers all three features
  List<Event> _generateDemoEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      // Today's classes
      Event(
        id: 'event_001',
        title: 'Interactive Design Lecture',
        description: 'Week 6: Lean UX and Iterative Design Process',
        startTime: today.add(const Duration(hours: 10)),
        endTime: today.add(const Duration(hours: 12)),
        location: 'CB02.04.56',
        type: EventType.class_,
        source: EventSource.personal,
        courseCode: '41021',
        creatorId: 'system',
      ),
      Event(
        id: 'event_002',
        title: 'Database Systems Lab',
        description: 'SQL Queries and Database Design',
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 16)),
        location: 'CB11.04.450',
        type: EventType.class_,
        source: EventSource.personal,
        courseCode: '31244',
        creatorId: 'system',
      ),
      
      // UXID Society Events - Real events from their page
      Event(
        id: 'event_003',
        title: 'Turning User Research into Design Decisions',
        description: 'Learn to turn user insights into design actions through expert tips, hands-on activities, and interactive games for confident research.',
        startTime: today.add(const Duration(days: 2, hours: 18)),
        endTime: today.add(const Duration(days: 2, hours: 20, minutes: 30)),
        location: 'TBA - Check UXID Discord for updates',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_001', // UXID Society
        creatorId: 'user_002',
        attendeeIds: ['user_001', 'user_002', 'user_005'],
      ),
      
      Event(
        id: 'event_004',
        title: 'Figma to Framer',
        description: 'If you\'re in Project UX, interested in learning design or preparing for an upcoming designation! This event is for you!',
        startTime: today.add(const Duration(days: 12, hours: 10)),
        endTime: today.add(const Duration(days: 13, hours: 17)),
        location: 'TBA - Check UXID Discord for updates',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_001', // UXID Society
        creatorId: 'user_002',
        attendeeIds: ['user_001', 'user_002'],
      ),
      
      Event(
        id: 'event_011',
        title: 'Sketch It, Test It, Fix It',
        description: 'This session covers rapid prototyping, from selecting fidelity to testing, using client feedback and activities to build user-focused designs',
        startTime: today.add(const Duration(days: 16, hours: 18)),
        endTime: today.add(const Duration(days: 16, hours: 20, minutes: 30)),
        location: 'TBA - Check UXID Discord for updates',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_001', // UXID Society
        creatorId: 'user_002',
        attendeeIds: ['user_001', 'user_005'],
      ),
      
      Event(
        id: 'event_012',
        title: 'UI Game-ification On Figma Workshop',
        description: 'Join us for UI Game-ification with game researcher Marell Bito, as we explore how gamification transforms everyday interfaces into engaging experiences.',
        startTime: today.add(const Duration(days: 22, hours: 18)),
        endTime: today.add(const Duration(days: 22, hours: 20)),
        location: 'TBA - Check UXID Discord for updates',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_001', // UXID Society
        creatorId: 'user_002',
        attendeeIds: ['user_001', 'user_002'],
      ),
      
      Event(
        id: 'event_013',
        title: 'Communicating Design with Impact',
        description: 'Gain skills to pitch designs persuasively, frame ideas, handle client pushback, and create engaging proposals for presentations and showcases.',
        startTime: today.add(const Duration(days: 30, hours: 18)),
        endTime: today.add(const Duration(days: 30, hours: 20, minutes: 30)),
        location: 'TBA - Check UXID Discord for updates',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_001', // UXID Society
        creatorId: 'user_002',
        attendeeIds: ['user_001'],
      ),
      
      Event(
        id: 'event_005',
        title: 'Assignment 2 Due',
        description: 'Interactive Design Portfolio submission deadline',
        startTime: today.add(const Duration(days: 5)),
        endTime: today.add(const Duration(days: 5)),
        location: 'Canvas Submission',
        type: EventType.assignment,
        source: EventSource.personal,
        courseCode: '41021',
        isAllDay: true,
        creatorId: 'system',
      ),
      
      // ProgSoc Events
      Event(
        id: 'event_015',
        title: 'Weekly Coding Workshop: Python for Beginners',
        description: 'Learn Python fundamentals in a supportive environment. Perfect for beginners or those looking to brush up on their skills. Laptops provided.',
        startTime: today.add(const Duration(days: 4, hours: 18)),
        endTime: today.add(const Duration(days: 4, hours: 20)),
        location: 'CB11.04.450, 81 Broadway, Ultimo NSW 2007',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_002', // ProgSoc
        creatorId: 'user_003',
        attendeeIds: ['user_001', 'user_003', 'user_005'],
      ),
      
      Event(
        id: 'event_016',
        title: 'Hackathon 2025: Build for Good',
        description: '48-hour hackathon focused on creating technology solutions for social impact. Teams, food, and prizes provided. All skill levels welcome.',
        startTime: today.add(const Duration(days: 21, hours: 18)),
        endTime: today.add(const Duration(days: 23, hours: 15)),
        location: 'Building 11, Multiple Floors',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_002', // ProgSoc
        creatorId: 'user_003',
        attendeeIds: ['user_001', 'user_003', 'user_005'],
      ),
      
      // Personal events
      Event(
        id: 'event_006',
        title: 'Study Session with Sarah',
        description: 'Database design project collaboration',
        startTime: today.add(const Duration(days: 1, hours: 15)),
        endTime: today.add(const Duration(days: 1, hours: 17)),
        location: 'Library Level 3',
        type: EventType.personal,
        source: EventSource.shared,
        creatorId: 'user_001',
        attendeeIds: ['user_001', 'user_002'],
      ),
      
      // Next week
      // Engineering Society Events
      Event(
        id: 'event_017',
        title: 'Engineering Industry Networking Night',
        description: 'Connect with industry professionals, alumni, and potential employers. Learn about career opportunities across different engineering disciplines.',
        startTime: today.add(const Duration(days: 12, hours: 18)),
        endTime: today.add(const Duration(days: 12, hours: 21)),
        location: 'Great Hall, UTS Building 2',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_003', // Engineering Society
        creatorId: 'user_004',
        attendeeIds: ['user_003', 'user_004'],
      ),
      
      // Car Society Events
      Event(
        id: 'event_018',
        title: 'Monthly Car Meet & Coffee',
        description: 'Casual car meet in the UTS parking area. Bring your ride, check out others\' cars, and connect with fellow automotive enthusiasts over coffee.',
        startTime: today.add(const Duration(days: 6, hours: 8)),
        endTime: today.add(const Duration(days: 6, hours: 11)),
        location: 'UTS Parking Area, Harris Street',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_004', // Car Society
        creatorId: 'user_005',
        attendeeIds: ['user_005'],
      ),
      
      // Dinner Society Events  
      Event(
        id: 'event_019',
        title: 'Chinatown Food Tour',
        description: 'Guided tour through Sydney\'s Chinatown with stops at authentic restaurants, dumplings houses, and dessert spots. Experience diverse Asian cuisines.',
        startTime: today.add(const Duration(days: 14, hours: 17)),
        endTime: today.add(const Duration(days: 14, hours: 21)),
        location: 'Chinatown, Sydney (Meet at UTS Building 1)',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_009', // Dinner Society
        creatorId: 'user_004',
        attendeeIds: ['user_001', 'user_004'],
      ),
      
      Event(
        id: 'event_007',
        title: 'Pitch Competition',
        description: 'Present your startup ideas to industry judges. Prizes available!',
        startTime: today.add(const Duration(days: 8, hours: 18)),
        endTime: today.add(const Duration(days: 8, hours: 21)),
        location: 'Great Hall',
        type: EventType.society,
        source: EventSource.societies,
        societyId: 'soc_005',
        creatorId: 'user_002',
        attendeeIds: ['user_001', 'user_004'],
      ),
      
      // Friend events (EventSource.friends) - visible from friend's schedules
      Event(
        id: 'event_008',
        title: 'Sarah\'s Design Presentation',
        description: 'Final design presentation for UX course',
        startTime: today.add(const Duration(hours: 13)),
        endTime: today.add(const Duration(hours: 14)),
        location: 'Design Studio B',
        type: EventType.class_,
        source: EventSource.friends,
        courseCode: 'DES301',
        creatorId: 'user_002',
        attendeeIds: ['user_002'],
      ),
      
      Event(
        id: 'event_009',
        title: 'James\' Database Exam',
        description: 'Final exam for database systems',
        startTime: today.add(const Duration(days: 3, hours: 9)),
        endTime: today.add(const Duration(days: 3, hours: 11)),
        location: 'CB11.05.200',
        type: EventType.assignment,
        source: EventSource.friends,
        courseCode: '31244',
        creatorId: 'user_005',
        attendeeIds: ['user_005'],
      ),
      
      Event(
        id: 'event_010',
        title: 'Sarah\'s Portfolio Review',
        description: 'Design portfolio presentation and feedback session',
        startTime: today.add(const Duration(days: 4, hours: 15)),
        endTime: today.add(const Duration(days: 4, hours: 16)),
        location: 'Design Studio C',
        type: EventType.personal,
        source: EventSource.friends,
        creatorId: 'user_002',
        attendeeIds: ['user_002'],
      ),
    ];
  }

  // Synchronous getters for backward compatibility
  List<User> get users {
    if (!_isInitialized) {
      // Auto-initialize synchronously with a fallback to empty data
      _initializeDataSync();
    }
    return _users ?? [];
  }
  
  // Async getter for explicit async loading
  Future<List<User>> get usersAsync async {
    await _initializeData();
    return _users!;
  }
  List<Society> get societies {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return List.unmodifiable(_societies ?? []);
  }
  
  Future<List<Society>> get societiesAsync async {
    await _initializeData();
    return List.unmodifiable(_societies!);
  }
  List<Event> get events {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return _events ?? [];
  }
  
  Future<List<Event>> get eventsAsync async {
    await _initializeData();
    return _events!;
  }

  // Helper methods for common queries (cached for performance)
  List<User> get friends {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return users.where((user) => user.id != currentUser.id).toList();
  }
  
  List<Society> get joinedSocieties {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return societies.where((society) => society.isJoined).toList();
  }
  
  List<Event> get todayEvents {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return events.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();
  }
  
  // Async versions for initial loading
  Future<List<User>> get friendsAsync async {
    await _initializeData();
    return users.where((user) => user.id != currentUser.id).toList();
  }
  
  Future<List<Society>> get joinedSocietiesAsync async {
    await _initializeData();
    return societies.where((society) => society.isJoined).toList();
  }
  
  Future<List<Event>> get todayEventsAsync async {
    await _initializeData();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return events.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();
  }

  // Method to get events within a date range
  List<Event> getEventsByDateRange(DateTime startDate, DateTime endDate) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return events.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
  
  Future<List<Event>> getEventsByDateRangeAsync(DateTime startDate, DateTime endDate) async {
    await _initializeData();
    return events.where((event) {
      return event.startTime.isAfter(startDate) && event.startTime.isBefore(endDate);
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Methods to modify data (for demo purposes)
  void joinSociety(String societyId) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    final index = _societies!.indexWhere((s) => s.id == societyId);
    if (index != -1) {
      _societies![index] = _societies![index].copyWith(
        isJoined: true,
        memberCount: _societies![index].memberCount + 1,
      );
    }
  }

  void leaveSociety(String societyId) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    final index = _societies!.indexWhere((s) => s.id == societyId);
    if (index != -1) {
      _societies![index] = _societies![index].copyWith(
        isJoined: false,
        memberCount: _societies![index].memberCount - 1,
      );
    }
  }

  User? getUserById(String id) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Society? getSocietyById(String id) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    try {
      return societies.firstWhere((society) => society.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<User?> getUserByIdAsync(String id) async {
    await _initializeData();
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Society?> getSocietyByIdAsync(String id) async {
    await _initializeData();
    try {
      return societies.firstWhere((society) => society.id == id);
    } catch (e) {
      return null;
    }
  }

  // Cache events to avoid regenerating on every access
  static DateTime? _lastEventGeneration;
  static const Duration _eventCacheExpiry = Duration(hours: 1);

  // Create demo events - simplified hardcoded version for sync fallback
  List<Event> _createDemoEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      Event(
        id: 'event_001',
        title: 'Interactive Design Lecture',
        description: 'Week 6: Lean UX and Iterative Design Process',
        startTime: today.add(const Duration(hours: 10)),
        endTime: today.add(const Duration(hours: 12)),
        location: 'CB02.04.56',
        type: EventType.class_,
        source: EventSource.personal,
        courseCode: '41021',
        creatorId: 'system',
      ),
      Event(
        id: 'event_002',
        title: 'Database Systems Lab',
        description: 'SQL Queries and Database Design',
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 16)),
        location: 'CB11.04.450',
        type: EventType.class_,
        source: EventSource.personal,
        courseCode: '31244',
        creatorId: 'system',
      ),
    ];
  }

  // Create demo locations (UTS Campus)
  List<Location> _createDemoLocations() {
    final now = DateTime.now();
    return [
      Location(
        id: 'loc_001',
        name: 'Interactive Design Studio',
        building: 'Building 2',
        room: '04.56',
        floor: '4',
        type: LocationType.classroom,
        latitude: -33.8838,
        longitude: 151.2003,
        description: 'Interactive design studio with collaborative workspaces',
        isAccessible: true,
        capacity: 30,
        amenities: ['Projector', 'Whiteboard', 'Collaborative tables'],
        createdAt: now,
      ),
      Location(
        id: 'loc_002',
        name: 'Database Lab',
        building: 'Building 11',
        room: '04.450',
        floor: '4',
        type: LocationType.lab,
        latitude: -33.8842,
        longitude: 151.2004,
        description: 'Computer lab for database systems',
        isAccessible: true,
        capacity: 40,
        amenities: ['Computers', 'Database software', 'Projector'],
        createdAt: now,
      ),
      Location(
        id: 'loc_003',
        name: 'Student Hub',
        building: 'Building 11',
        room: '06.106',
        floor: '6',
        type: LocationType.common,
        latitude: -33.8842,
        longitude: 151.2004,
        description: 'Social space for students and society meetings',
        isAccessible: true,
        capacity: 50,
        amenities: ['WiFi', 'Seating', 'Presentation equipment'],
        createdAt: now,
      ),
      Location(
        id: 'loc_004',
        name: 'Library Study Area',
        building: 'UTS Library',
        room: 'Level 3',
        floor: '3',
        type: LocationType.study,
        latitude: -33.8841,
        longitude: 151.2006,
        description: 'Quiet study area with individual workspaces',
        isAccessible: true,
        capacity: 80,
        amenities: ['Silent zone', 'Power outlets', 'WiFi'],
        createdAt: now,
      ),
      Location(
        id: 'loc_005',
        name: 'Design Studio',
        building: 'Building 6',
        room: 'Studio A',
        floor: '2',
        type: LocationType.classroom,
        latitude: -33.8839,
        longitude: 151.2001,
        description: 'Creative design studio with professional equipment',
        isAccessible: true,
        capacity: 25,
        amenities: ['Design software', 'Large displays', 'Drawing tablets'],
        createdAt: now,
      ),
      Location(
        id: 'loc_006',
        name: 'Building 1 Lobby',
        building: 'Building 1',
        room: 'Ground Floor',
        floor: 'G',
        type: LocationType.common,
        latitude: -33.8836,
        longitude: 151.2002,
        description: 'Main entrance and lobby area of UTS Building 1',
        isAccessible: true,
        capacity: 100,
        amenities: ['Information desk', 'WiFi', 'Seating areas'],
        createdAt: now,
      ),
      Location(
        id: 'loc_007',
        name: 'Student Centre',
        building: 'Building 1',
        room: 'Various',
        floor: '1-2',
        type: LocationType.common,
        latitude: -33.8836,
        longitude: 151.2002,
        description: 'Student services and support facilities',
        isAccessible: true,
        capacity: 200,
        amenities: ['Student services', 'Food court', 'Study spaces'],
        createdAt: now,
      ),
    ];
  }

  // Create privacy settings for all users
  List<PrivacySettings> _createDemoPrivacySettings() {
    final now = DateTime.now();
    return [
      // Andrea Fernandez (current user) - moderate privacy
      PrivacySettings(
        id: 'privacy_001',
        userId: 'user_001',
        createdAt: now,
        locationSharing: LocationSharingLevel.friends,
        shareExactLocation: false,
        shareBuildingOnly: true,
        timetableSharing: TimetableSharingLevel.friends,
        shareFreeTimes: true,
        shareClassDetails: false,
        onlineStatusVisibility: OnlineStatusVisibility.friends,
        showLastSeen: true,
        perFriendTimetableSharing: {
          'user_002': TimetableSharingLevel.friends,
          'user_005': TimetableSharingLevel.friends,
        },
      ),
      // Sarah Mitchell - open privacy
      PrivacySettings(
        id: 'privacy_002',
        userId: 'user_002',
        createdAt: now,
        locationSharing: LocationSharingLevel.friends,
        shareExactLocation: true,
        shareBuildingOnly: false,
        timetableSharing: TimetableSharingLevel.friends,
        shareFreeTimes: true,
        shareClassDetails: true,
        onlineStatusVisibility: OnlineStatusVisibility.friends,
        showLastSeen: true,
      ),
      // Marcus Rodriguez - private settings
      PrivacySettings(
        id: 'privacy_003',
        userId: 'user_003',
        createdAt: now,
        locationSharing: LocationSharingLevel.friends,
        shareExactLocation: false,
        shareBuildingOnly: true,
        timetableSharing: TimetableSharingLevel.friends,
        shareFreeTimes: false,
        shareClassDetails: false,
        onlineStatusVisibility: OnlineStatusVisibility.friends,
        showLastSeen: false,
      ),
      // Emma Watson - new user, default settings
      PrivacySettings(
        id: 'privacy_004',
        userId: 'user_004',
        createdAt: now,
        locationSharing: LocationSharingLevel.friends,
        timetableSharing: TimetableSharingLevel.friends,
        onlineStatusVisibility: OnlineStatusVisibility.friends,
      ),
      // James Kim - tech-savvy, selective sharing
      PrivacySettings(
        id: 'privacy_005',
        userId: 'user_005',
        createdAt: now,
        locationSharing: LocationSharingLevel.friends,
        shareExactLocation: false,
        shareBuildingOnly: true,
        timetableSharing: TimetableSharingLevel.friends,
        shareFreeTimes: true,
        shareClassDetails: false,
        onlineStatusVisibility: OnlineStatusVisibility.friends,
        showLastSeen: true,
      ),
    ];
  }

  // Create users with interconnected relationships
  List<User> _createDemoUsersWithRelationships() {
    final now = DateTime.now();
    return [
      // Andrea Fernandez (current user) - friends with Sarah and James
      User(
        id: 'user_001',
        name: 'Andrea Fernandez',
        email: 'andrea.fernandez@student.uts.edu.au',
        course: 'Bachelor of Information Technology',
        year: '2nd Year',
        privacySettingsId: 'privacy_001',
        profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Andrea',
        isOnline: true,
        status: UserStatus.online,
        currentLocationId: 'loc_001',
        currentBuilding: 'Building 2',
        currentRoom: '04.56',
        latitude: -33.8838,
        longitude: 151.2003,
        locationUpdatedAt: now.subtract(const Duration(minutes: 10)),
        statusMessage: 'In Interactive Design class',
        friendIds: ['user_002', 'user_005'],
        pendingFriendRequests: ['user_003'],
        sentFriendRequests: [],
      ),
      // Sarah Mitchell - friends with Andrea, location shared
      User(
        id: 'user_002',
        name: 'Sarah Mitchell',
        email: 'sarah.mitchell@student.uts.edu.au',
        course: 'Bachelor of Design',
        year: '3rd Year',
        privacySettingsId: 'privacy_002',
        profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Sarah',
        isOnline: true,
        lastSeen: now.subtract(const Duration(minutes: 5)),
        status: UserStatus.studying,
        currentLocationId: 'loc_004',
        currentBuilding: 'UTS Library',
        currentRoom: 'Level 3',
        latitude: -33.8841,
        longitude: 151.2006,
        locationUpdatedAt: now.subtract(const Duration(minutes: 20)),
        statusMessage: 'Working on design project',
        friendIds: ['user_001'],
        pendingFriendRequests: [],
        sentFriendRequests: [],
      ),
      // Marcus Rodriguez - sent friend request to Andrea
      User(
        id: 'user_003',
        name: 'Marcus Rodriguez',
        email: 'marcus.rodriguez@student.uts.edu.au',
        course: 'Bachelor of Engineering',
        year: '2nd Year',
        privacySettingsId: 'privacy_003',
        profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Marcus',
        isOnline: false,
        lastSeen: now.subtract(const Duration(hours: 2)),
        status: UserStatus.offline,
        currentLocationId: null,
        locationUpdatedAt: now.subtract(const Duration(hours: 3)),
        friendIds: [],
        pendingFriendRequests: [],
        sentFriendRequests: ['user_001'],
      ),
      // Emma Watson - new user, not many connections yet
      User(
        id: 'user_004',
        name: 'Emma Watson',
        email: 'emma.watson@student.uts.edu.au',
        course: 'Bachelor of Business',
        year: '1st Year',
        privacySettingsId: 'privacy_004',
        profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Emma',
        isOnline: true,
        status: UserStatus.online,
        statusMessage: 'New to UTS!',
        friendIds: [],
        pendingFriendRequests: [],
        sentFriendRequests: [],
      ),
      // James Kim - friends with Andrea, same course
      User(
        id: 'user_005',
        name: 'James Kim',
        email: 'james.kim@student.uts.edu.au',
        course: 'Bachelor of Information Technology',
        year: '2nd Year',
        privacySettingsId: 'privacy_005',
        profileImageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=James',
        isOnline: false,
        lastSeen: now.subtract(const Duration(minutes: 30)),
        status: UserStatus.away,
        currentLocationId: 'loc_002',
        currentBuilding: 'Building 11',
        currentRoom: '04.450',
        latitude: -33.8842,
        longitude: 151.2004,
        locationUpdatedAt: now.subtract(const Duration(minutes: 35)),
        statusMessage: 'Just finished database lab',
        friendIds: ['user_001'],
        pendingFriendRequests: [],
        sentFriendRequests: [],
      ),
    ];
  }

  // Create friend requests
  List<FriendRequest> _createDemoFriendRequests() {
    final now = DateTime.now();
    return [
      // Marcus sent friend request to Andrea (pending)
      FriendRequest(
        id: 'freq_001',
        senderId: 'user_003',
        receiverId: 'user_001',
        status: FriendRequestStatus.pending,
        createdAt: now.subtract(const Duration(days: 1)),
        message: 'Hey Andrea! We\'re in the same Interactive Design class. Would love to connect!',
      ),
      // Previous accepted friend request between Andrea and Sarah
      FriendRequest(
        id: 'freq_002',
        senderId: 'user_001',
        receiverId: 'user_002',
        status: FriendRequestStatus.accepted,
        createdAt: now.subtract(const Duration(days: 15)),
        respondedAt: now.subtract(const Duration(days: 14)),
        message: 'Saw you in design class, let\'s be study buddies!',
      ),
      // Previous accepted friend request between Andrea and James
      FriendRequest(
        id: 'freq_003',
        senderId: 'user_005',
        receiverId: 'user_001',
        status: FriendRequestStatus.accepted,
        createdAt: now.subtract(const Duration(days: 30)),
        respondedAt: now.subtract(const Duration(days: 29)),
        message: 'Fellow IT student here! Let\'s connect.',
      ),
    ];
  }

  // Lazy-loaded getters for new data (mutable for service updates)
  List<PrivacySettings> get privacySettings {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return _privacySettings ?? [];
  }
  
  Future<List<PrivacySettings>> get privacySettingsAsync async {
    await _initializeData();
    return _privacySettings!;
  }
  
  List<Location> get locations {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return List.unmodifiable(_locations ?? []);
  }
  
  Future<List<Location>> get locationsAsync async {
    await _initializeData();
    return List.unmodifiable(_locations!);
  }
  
  List<FriendRequest> get friendRequests {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return _friendRequests ?? [];
  }
  
  Future<List<FriendRequest>> get friendRequestsAsync async {
    await _initializeData();
    return _friendRequests!;
  }

  // Helper methods for new interconnected data
  PrivacySettings? getPrivacySettingsForUser(String userId) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    try {
      return privacySettings.firstWhere((settings) => settings.userId == userId);
    } catch (e) {
      return null;
    }
  }

  Location? getLocationById(String id) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    try {
      return locations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  List<FriendRequest> getPendingFriendRequests(String userId) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return friendRequests.where((request) => 
      request.receiverId == userId && request.isPending
    ).toList();
  }

  List<FriendRequest> getSentFriendRequests(String userId) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    return friendRequests.where((request) => 
      request.senderId == userId && request.isPending
    ).toList();
  }
  
  // Async versions for initial loading
  Future<PrivacySettings?> getPrivacySettingsForUserAsync(String userId) async {
    await _initializeData();
    try {
      return privacySettings.firstWhere((settings) => settings.userId == userId);
    } catch (e) {
      return null;
    }
  }

  Future<Location?> getLocationByIdAsync(String id) async {
    await _initializeData();
    try {
      return locations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<FriendRequest>> getPendingFriendRequestsAsync(String userId) async {
    await _initializeData();
    return friendRequests.where((request) => 
      request.receiverId == userId && request.isPending
    ).toList();
  }

  Future<List<FriendRequest>> getSentFriendRequestsAsync(String userId) async {
    await _initializeData();
    return friendRequests.where((request) => 
      request.senderId == userId && request.isPending
    ).toList();
  }

  // Friend management methods
  bool areFriends(String userId1, String userId2) {
    final user1 = getUserById(userId1);
    final user2 = getUserById(userId2);
    return user1?.friendIds.contains(userId2) == true && 
           user2?.friendIds.contains(userId1) == true;
  }

  List<User> getFriendsForUser(String userId) {
    if (!_isInitialized) {
      _initializeDataSync();
    }
    final user = getUserById(userId);
    if (user == null) return [];
    
    return user.friendIds.map((friendId) => getUserById(friendId))
        .where((friend) => friend != null)
        .cast<User>()
        .toList();
  }
  
  Future<List<User>> getFriendsForUserAsync(String userId) async {
    await _initializeData();
    final user = getUserById(userId);
    if (user == null) return [];
    
    return user.friendIds.map((friendId) => getUserById(friendId))
        .where((friend) => friend != null)
        .cast<User>()
        .toList();
  }
}