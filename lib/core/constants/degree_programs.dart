class DegreePrograms {
  static const List<String> bachelorPrograms = [
    // Engineering & Technology
    'Bachelor of Engineering (Honours)',
    'Bachelor of Information Technology',
    'Bachelor of Computer Science',
    'Bachelor of Software Engineering',
    'Bachelor of Data Science and Innovation',
    'Bachelor of Cybersecurity',
    'Bachelor of Civil Engineering',
    'Bachelor of Mechanical Engineering',
    'Bachelor of Electrical Engineering',
    'Bachelor of Biomedical Engineering',
    'Bachelor of Environmental Engineering',
    'Bachelor of Chemical Engineering',
    'Bachelor of Aerospace Engineering',
    'Bachelor of Telecommunications Engineering',
    'Bachelor of Robotics and Mechatronics Engineering',

    // Design & Creative Arts
    'Bachelor of Design',
    'Bachelor of Design in Fashion and Textiles',
    'Bachelor of Design in Interior Architecture',
    'Bachelor of Design in Product Design',
    'Bachelor of Design in Visual Communication',
    'Bachelor of Design in Animation and Visual Effects',
    'Bachelor of Design in Photography and Situated Media',
    'Bachelor of Creative Intelligence and Innovation',
    'Bachelor of Fine Arts',
    'Bachelor of Creative Writing',
    'Bachelor of Digital and Social Media',
    'Bachelor of Music and Sound Design',

    // Business & Economics
    'Bachelor of Business',
    'Bachelor of Business Administration',
    'Bachelor of Accounting',
    'Bachelor of Economics',
    'Bachelor of Finance',
    'Bachelor of Marketing',
    'Bachelor of Human Resource Management',
    'Bachelor of International Business',
    'Bachelor of Entrepreneurship',
    'Bachelor of Sport and Exercise Management',
    'Bachelor of Event Management',
    'Bachelor of Tourism Management',

    // Science & Health
    'Bachelor of Science',
    'Bachelor of Applied Science',
    'Bachelor of Biotechnology',
    'Bachelor of Environmental Science',
    'Bachelor of Medical Science',
    'Bachelor of Pharmacy',
    'Bachelor of Nursing',
    'Bachelor of Physiotherapy',
    'Bachelor of Psychology',
    'Bachelor of Public Health',
    'Bachelor of Nutrition and Dietetics',
    'Bachelor of Occupational Therapy',
    'Bachelor of Speech Pathology',
    'Bachelor of Midwifery',
    'Bachelor of Paramedicine',
    'Bachelor of Sport and Exercise Science',
    'Bachelor of Exercise Physiology',

    // Law & Justice
    'Bachelor of Laws',
    'Bachelor of Criminology',
    'Bachelor of Policing',
    'Bachelor of Legal Studies',
    'Bachelor of Criminal Justice',

    // Communication & Media
    'Bachelor of Communication',
    'Bachelor of Media Arts and Production',
    'Bachelor of Journalism',
    'Bachelor of Public Relations',
    'Bachelor of Advertising and Marketing Communications',
    'Bachelor of Screen Media',

    // Education & Social Sciences
    'Bachelor of Education',
    'Bachelor of Teaching',
    'Bachelor of Social Work',
    'Bachelor of Social Science',
    'Bachelor of International Studies',
    'Bachelor of Politics and International Relations',
    'Bachelor of Anthropology',
    'Bachelor of Sociology',
    'Bachelor of Philosophy',
    'Bachelor of History',
    'Bachelor of Languages and Linguistics',

    // Architecture & Built Environment
    'Bachelor of Architecture',
    'Bachelor of Construction Management',
    'Bachelor of Property Economics',
    'Bachelor of Urban Planning',
    'Bachelor of Landscape Architecture',

    // Mathematics & Statistics
    'Bachelor of Mathematics',
    'Bachelor of Statistics',
    'Bachelor of Applied Mathematics',
    'Bachelor of Actuarial Studies',
    'Bachelor of Financial Mathematics',
  ];

  static const List<String> masterPrograms = [
    // Engineering & Technology
    'Master of Engineering',
    'Master of Information Technology',
    'Master of Computer Science',
    'Master of Data Science and Innovation',
    'Master of Cybersecurity',
    'Master of Software Engineering',
    'Master of Artificial Intelligence',
    'Master of Telecommunications Engineering',
    'Master of Project Management',

    // Business & Management
    'Master of Business Administration (MBA)',
    'Master of Business',
    'Master of Management',
    'Master of Finance',
    'Master of Accounting',
    'Master of Marketing',
    'Master of Human Resource Management',
    'Master of International Business',
    'Master of Entrepreneurship',
    'Master of Business Analytics',
    'Master of Digital Business',

    // Design & Creative Arts
    'Master of Design',
    'Master of Architecture',
    'Master of Creative Writing',
    'Master of Digital Creative Enterprise',
    'Master of Creative Intelligence and Innovation',
    'Master of Animation and Visualisation',

    // Health & Medicine
    'Master of Public Health',
    'Master of Health Services Management',
    'Master of Nursing',
    'Master of Pharmacy',
    'Master of Clinical Psychology',
    'Master of Physiotherapy',
    'Master of Genetic Counselling',
    'Master of Health Economics',

    // Law & Justice
    'Master of Laws (LLM)',
    'Master of Legal Studies',
    'Juris Doctor',

    // Education & Social Sciences
    'Master of Education',
    'Master of Teaching',
    'Master of Social Work',
    'Master of International Relations',
    'Master of Planning',
    'Master of Urban and Regional Planning',

    // Research Programs
    'Master of Philosophy',
    'Master of Research',
    'Master by Research',
  ];

  static const List<String> doctoratePrograms = [
    'Doctor of Philosophy (PhD)',
    'Doctor of Business Administration (DBA)',
    'Doctor of Education (EdD)',
    'Doctor of Creative Arts',
    'Doctor of Psychology',
    'Doctor of Engineering',
    'Doctor of Medicine',
    'Doctor of Dental Medicine',
    'Doctor of Veterinary Medicine',
    'Doctor of Pharmacy',
    'Doctor of Physiotherapy',
    'Doctor of Nursing Practice',
  ];

  static const List<String> diplomaPrograms = [
    'Diploma of Engineering',
    'Diploma of Information Technology',
    'Diploma of Business',
    'Diploma of Design',
    'Diploma of Health Sciences',
    'Diploma of Community Services',
    'Diploma of Education Support',
    'Diploma of Languages',
    'Diploma of Music',
    'Diploma of Creative Writing',
    'Advanced Diploma of Engineering Technology',
    'Advanced Diploma of Information Technology',
    'Advanced Diploma of Business',
    'Graduate Diploma of Education',
    'Graduate Diploma of Psychology',
    'Graduate Diploma of Information Technology',
    'Graduate Diploma of Business Administration',
    'Graduate Diploma of Engineering',
    'Graduate Diploma of Health Sciences',
    'Graduate Diploma of Design',
  ];

  static const List<String> certificatePrograms = [
    'Certificate IV in Information Technology',
    'Certificate IV in Business',
    'Certificate IV in Design',
    'Certificate IV in Engineering Technology',
    'Certificate IV in Community Services',
    'Certificate IV in Education Support',
    'Certificate III in Information Technology',
    'Certificate III in Business',
    'Certificate III in Engineering',
    'Graduate Certificate in Education',
    'Graduate Certificate in Business',
    'Graduate Certificate in Information Technology',
    'Graduate Certificate in Health Sciences',
    'Graduate Certificate in Engineering',
    'Graduate Certificate in Design',
    'Graduate Certificate in Project Management',
    'Graduate Certificate in Data Science',
    'Graduate Certificate in Cybersecurity',
  ];

  // Comprehensive list combining all programs
  static List<String> get allPrograms {
    return [
      ...bachelorPrograms,
      ...masterPrograms,
      ...doctoratePrograms,
      ...diplomaPrograms,
      ...certificatePrograms,
    ]..sort();
  }

  // Common programs for quick access (most popular)
  static const List<String> popularPrograms = [
    'Bachelor of Information Technology',
    'Bachelor of Business',
    'Bachelor of Engineering (Honours)',
    'Bachelor of Design',
    'Bachelor of Science',
    'Bachelor of Communication',
    'Bachelor of Laws',
    'Bachelor of Education',
    'Bachelor of Nursing',
    'Bachelor of Psychology',
    'Master of Business Administration (MBA)',
    'Master of Information Technology',
    'Master of Engineering',
    'Master of Design',
    'Doctor of Philosophy (PhD)',
  ];

  // Search function for autocomplete
  static List<String> searchPrograms(String query) {
    if (query.isEmpty) return popularPrograms;

    final lowercaseQuery = query.toLowerCase();
    return allPrograms
        .where((program) => program.toLowerCase().contains(lowercaseQuery))
        .toList();
  }
}