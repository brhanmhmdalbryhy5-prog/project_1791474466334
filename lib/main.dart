import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://sekchgllbimoedsjoumi.supabase.co';
const supabaseKey = 'sb_publishable_9zjs--DXxfYUQC-kC6vF-w_eWrw2rmO';

late final SupabaseClient db;

const bg = Color(0xFF101114);
const panel = Color(0xFF1B1D22);
const muted = Color(0xFF9CA3AF);

const subjectColors = <String, Color>{
  'الرياضيات': Color(0xFF4C8DFF),
  'اللغة العربية': Color(0xFFD4A04D),
  'الفيزياء': Color(0xFF29C7C9),
  'القرآن الكريم': Color(0xFF45B879),
  'الكيمياء': Color(0xFFA879F5),
  'اللغة الإنجليزية': Color(0xFFF06472),
  'التربية الإسلامية': Color(0xFF55B7A5),
  'الأحياء': Color(0xFFA6C94A),
};

Color subjectColor(String name) =>
    subjectColors[name] ?? const Color(0xFFB7BAC3);

String errorText(Object e) {
  if (e is AuthException) return e.message;
  if (e is PostgrestException) return e.message;
  return e.toString();
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  db = Supabase.instance.client;
  runApp(const BuraheiApp());
}

class BuraheiApp extends StatelessWidget {
  const BuraheiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'البريهي التعليمي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB7BAC3),
          surface: panel,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// =====================================================
// الدخول المباشر للطلاب
// =====================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

// =====================================================
// الصفحة الرئيسية
// =====================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> subjectsFuture;

  int tab = 0;

  @override
  void initState() {
    super.initState();
    subjectsFuture = loadSubjects();
  }

  Future<List<Map<String, dynamic>>> loadSubjects() async {
    final rows = await db
        .from('subjects')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> openAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'البريهي التعليمي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.school_rounded),
        actions: [
          IconButton(
            tooltip: 'دخول الإدارة',
            onPressed: openAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          IconButton(
            tooltip: 'تحديث المواد',
            onPressed: () {
              setState(() => subjectsFuture = loadSubjects());
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          SubjectsPage(
            subjectsFuture: subjectsFuture,
            onRetry: () {
              setState(() => subjectsFuture = loadSubjects());
            },
          ),
          const ServicesPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF191A1E),
        indicatorColor: const Color(0xFF363840),
        selectedIndex: tab,
        onDestinationSelected: (i) {
          setState(() => tab = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            label: 'الخدمات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// عرض المواد الدراسية
// =====================================================

class SubjectsPage extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> subjectsFuture;
  final VoidCallback onRetry;

  const SubjectsPage({
    super.key,
    required this.subjectsFuture,
    required this.onRetry,
  });

  IconData iconFor(String name) {
    if (name.contains('رياض')) return Icons.calculate_rounded;
    if (name.contains('عربي')) return Icons.menu_book_rounded;
    if (name.contains('فيزياء')) return Icons.bolt_rounded;
    if (name.contains('قرآن')) return Icons.auto_stories_rounded;
    if (name.contains('كيمياء')) return Icons.science_rounded;
    if (name.contains('إنجليزي')) return Icons.translate_rounded;
    if (name.contains('إسلام')) return Icons.mosque_rounded;
    if (name.contains('أحياء')) return Icons.biotech_rounded;
    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: subjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return ErrorView(
            message: errorText(snapshot.error!),
            onRetry: onRetry,
          );
        }

        final rows = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF303139),
                      Color(0xFF191A1E),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رحلتك نحو المعرفة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'اختر مادتك وابدأ التعلم',
                      style: TextStyle(
                        color: muted,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text('تعلّم  •  لخّص  •  اختبر نفسك'),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text(
                  'المواد الدراسية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (rows.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد مواد نشطة في قاعدة البيانات.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final subject = rows[i];
                      final name = '${subject['name'] ?? 'مادة'}';
                      final color = subjectColor(name);

                      return Material(
                        color: panel,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectLessonsPage(
                                  subject: subject,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: color.withOpacity(.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    iconFor(name),
                                    color: color,
                                    size: 28,
                                  ),
                                ),
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: rows.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'مع تحياتي برهان البريهي',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =====================================================
// صفحة الإعدادات - بدون حساب للطلاب
// =====================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Card(
          color: panel,
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.school_outlined),
            ),
            title: Text('البريهي التعليمي'),
            subtitle: Text(
              'تعلّم، راجع، واختبر فهمك دون الحاجة إلى حساب.',
            ),
          ),
        ),
        SizedBox(height: 28),
        Text(
          'مع تحياتي برهان البريهي',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
      ],
    );
  }
}

// =====================================================
// واجهة عامة للأخطاء
// =====================================================

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFF06472),
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
// =====================================================
// صفحة دروس المادة
// =====================================================

class SubjectLessonsPage extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectLessonsPage({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectLessonsPage> createState() =>
      _SubjectLessonsPageState();
}

class _SubjectLessonsPageState extends State<SubjectLessonsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadLessons();
  }

  Future<List<Map<String, dynamic>>> loadLessons() async {
    final data = await db
        .from('lessons')
        .select()
        .eq('subject_id', widget.subject['id'])
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    final subjectName = '${widget.subject['name'] ?? 'المادة'}';

    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: errorText(snapshot.error!),
              onRetry: () => setState(() => future = loadLessons()),
            );
          }

          final lessons = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeading(
                title: 'دروس $subjectName',
                subtitle: 'اختر درسًا لبدء القراءة',
              ),
              const SizedBox(height: 14),
              _FeatureTile(
                title: 'ملخصات المادة',
                subtitle: 'راجع أهم المعلومات',
                icon: Icons.summarize_outlined,
                color: const Color(0xFF55B7A5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectSummariesPage(
                        subject: widget.subject,
                      ),
                    ),
                  );
                },
              ),
              _FeatureTile(
                title: 'اختبر نفسك',
                subtitle: 'تدرب على أسئلة المادة',
                icon: Icons.quiz_outlined,
                color: const Color(0xFFB7BAC3),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectQuizPage(
                        subject: widget.subject,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              if (lessons.isEmpty)
                const _EmptyContent(
                  message: 'لا توجد دروس منشورة لهذه المادة حاليًا.',
                )
              else
                ...lessons.map(
                  (lesson) => Card(
                    color: panel,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF303139),
                        child: Icon(Icons.menu_book_outlined),
                      ),
                      title: Text(
                        '${lesson['title'] ?? 'درس بدون عنوان'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('اضغط لقراءة الدرس'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonDetailPage(
                              lesson: lesson,
                              subject: widget.subject,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================
// قراءة الدرس
// =====================================================

class LessonDetailPage extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final Map<String, dynamic> subject;

  const LessonDetailPage({
    super.key,
    required this.lesson,
    required this.subject,
  });

  String get content {
    return '${lesson['content'] ?? lesson['body'] ?? lesson['lesson_text'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson['title'] ?? 'الدرس'}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            '${subject['name'] ?? ''}',
            style: TextStyle(
              color: subjectColor('${subject['name'] ?? ''}'),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${lesson['title'] ?? 'الدرس'}',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 30),
          SelectableText(
            content.isEmpty ? 'لا يوجد محتوى لهذا الدرس.' : content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.9,
            ),
          ),
          const SizedBox(height: 30),
          _FeatureTile(
            title: 'ملخصات المادة',
            subtitle: 'انتقل إلى الملخصات',
            icon: Icons.summarize_outlined,
            color: const Color(0xFF55B7A5),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectSummariesPage(
                    subject: subject,
                  ),
                ),
              );
            },
          ),
          _FeatureTile(
            title: 'اختبر فهمك',
            subtitle: 'حل أسئلة هذه المادة',
            icon: Icons.quiz_outlined,
            color: const Color(0xFFB7BAC3),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectQuizPage(
                    subject: subject,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ملخصات المادة
// =====================================================

class SubjectSummariesPage extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectSummariesPage({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectSummariesPage> createState() =>
      _SubjectSummariesPageState();
}

class _SubjectSummariesPageState
    extends State<SubjectSummariesPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadSummaries();
  }

  Future<List<Map<String, dynamic>>> loadSummaries() async {
    final data = await db
        .from('summaries')
        .select()
        .eq('subject_id', widget.subject['id'])
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ملخصات ${widget.subject['name'] ?? ''}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: errorText(snapshot.error!),
              onRetry: () {
                setState(() => future = loadSummaries());
              },
            );
          }

          final summaries = snapshot.data ?? [];

          if (summaries.isEmpty) {
            return const _EmptyContent(
              message: 'لا توجد ملخصات منشورة لهذه المادة حتى الآن.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];

              return Card(
                color: panel,
                child: ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF55B7A5),
                  ),
                  title: Text(
                    '${summary['title'] ?? 'ملخص'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text('اضغط لقراءة الملخص'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReadingPage(
                          item: summary,
                          pageTitle: 'الملخص',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// صفحة قراءة الملخص
// =====================================================

class ReadingPage extends StatelessWidget {
  final Map<String, dynamic> item;
  final String pageTitle;

  const ReadingPage({
    super.key,
    required this.item,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final content =
        '${item['content'] ?? item['body'] ?? item['summary_text'] ?? ''}';

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            '${item['title'] ?? pageTitle}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 32),
          SelectableText(
            content.isEmpty ? 'لا يوجد محتوى للعرض.' : content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.9,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// الاختبارات متعددة الخيارات
// =====================================================

class SubjectQuizPage extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectQuizPage({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectQuizPage> createState() => _SubjectQuizPageState();
}

class _SubjectQuizPageState extends State<SubjectQuizPage> {
  bool loading = true;
  String? loadError;

  List<Map<String, dynamic>> questions = [];
  List<List<Map<String, dynamic>>> options = [];

  final Map<int, int> answers = {};

  bool submitted = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    loadQuiz();
  }

  Future<void> loadQuiz() async {
    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final questionData = await db
          .from('questions')
          .select()
          .eq('subject_id', widget.subject['id'])
          .eq('is_published', true)
          .order('created_at');

      final loadedQuestions =
          List<Map<String, dynamic>>.from(questionData);

      final loadedOptions = <List<Map<String, dynamic>>>[];

      for (final question in loadedQuestions) {
        final optionData = await db
            .from('question_options')
            .select()
            .eq('question_id', question['id']);

        loadedOptions.add(
          List<Map<String, dynamic>>.from(optionData),
        );
      }

      if (!mounted) return;

      setState(() {
        questions = loadedQuestions;
        options = loadedOptions;
        answers.clear();
        submitted = false;
        score = 0;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadError = errorText(e);
        loading = false;
      });
    }
  }

  void submitQuiz() {
    if (questions.isEmpty) return;

    int correct = 0;

    for (int i = 0; i < questions.length; i++) {
      final selected = answers[i];

      if (selected == null) continue;

      final questionOptions = options[i];

      if (selected >= 0 && selected < questionOptions.length) {
        if (questionOptions[selected]['is_correct'] == true) {
          correct++;
        }
      }
    }

    setState(() {
      score = correct;
      submitted = true;
    });
  }

  void restartQuiz() {
    setState(() {
      answers.clear();
      submitted = false;
      score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final percentage = questions.isEmpty
        ? 0
        : (score * 100 / questions.length).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار ${widget.subject['name'] ?? ''}'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? ErrorView(
                  message: loadError!,
                  onRetry: loadQuiz,
                )
              : questions.isEmpty
                  ? const _EmptyContent(
                      message: 'لا توجد أسئلة منشورة لهذه المادة.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (submitted) ...[
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: panel,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: percentage >= 50
                                    ? const Color(0xFF45B879)
                                    : const Color(0xFFF06472),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.assessment_outlined,
                                  size: 44,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'نتيجتك النهائية',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'الإجابات الصحيحة: $score من ${questions.length}',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          Text(
                            'عدد الأسئلة: ${questions.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        for (int i = 0; i < questions.length; i++)
                          _QuestionCard(
                            number: i + 1,
                            question: questions[i],
                            options: options[i],
                            selected: answers[i],
                            submitted: submitted,
                            onSelected: (value) {
                              setState(() => answers[i] = value);
                            },
                          ),
                        const SizedBox(height: 18),
                        if (!submitted)
                          FilledButton.icon(
                            onPressed: submitQuiz,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('إنهاء الاختبار'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: restartQuiz,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة الاختبار'),
                          ),
                      ],
                    ),
    );
  }
}

// =====================================================
// بطاقة السؤال
// =====================================================

class _QuestionCard extends StatelessWidget {
  final int number;
  final Map<String, dynamic> question;
  final List<Map<String, dynamic>> options;
  final int? selected;
  final bool submitted;
  final ValueChanged<int> onSelected;

  const _QuestionCard({
    required this.number,
    required this.question,
    required this.options,
    required this.selected,
    required this.submitted,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final text = question['question_text'] ??
        question['title'] ??
        'السؤال $number';

    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. $text',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (options.isEmpty)
              const Text(
                'لا توجد خيارات لهذا السؤال.',
                style: TextStyle(color: muted),
              )
            else
              ...List.generate(options.length, (index) {
                final option = options[index];
                final isCorrect = option['is_correct'] == true;

                Color? tileColor;

                if (submitted && isCorrect) {
                  tileColor = const Color(0xFF204C37);
                } else if (submitted && selected == index) {
                  tileColor = const Color(0xFF5B292E);
                }

                return Card(
                  color: tileColor ?? const Color(0xFF24262C),
                  child: RadioListTile<int>(
                    value: index,
                    groupValue: selected,
                    onChanged: submitted
                        ? null
                        : (value) {
                            if (value != null) onSelected(value);
                          },
                    title: Text(
                      '${option['option_text'] ?? option['text'] ?? ''}',
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// عناصر واجهة مشتركة
// =====================================================

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final String message;

  const _EmptyContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: muted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// =====================================================
// صفحة الخدمات
// =====================================================

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  Future<void> openPage(
    BuildContext context,
    Widget page,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'الخدمات التعليمية',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'اختر الخدمة التي تريد استخدامها.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 18),
        _FeatureTile(
          title: 'الملخصات',
          subtitle: 'اختر مادة لمراجعة ملخصاتها',
          icon: Icons.summarize_outlined,
          color: const Color(0xFF55B7A5),
          onTap: () => openPage(
            context,
            const SummarySubjectsPage(),
          ),
        ),
        _FeatureTile(
          title: 'الاختبارات',
          subtitle: 'اختبر معلوماتك في أي مادة',
          icon: Icons.quiz_outlined,
          color: const Color(0xFFB7BAC3),
          onTap: () => openPage(
            context,
            const QuizSubjectsPage(),
          ),
        ),
        _FeatureTile(
          title: 'الإشعارات',
          subtitle: 'تابع الإعلانات والتنبيهات الجديدة',
          icon: Icons.notifications_active_outlined,
          color: const Color(0xFFF0B45B),
          onTap: () => openPage(
            context,
            const NotificationsPage(),
          ),
        ),
        _FeatureTile(
          title: 'طلب مساعدة',
          subtitle: 'أرسل سؤالك أو مشكلتك إلى الإدارة',
          icon: Icons.support_agent_rounded,
          color: const Color(0xFFF06472),
          onTap: () => openPage(
            context,
            const RequestPage(),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// اختيار المادة للملخصات
// =====================================================

class SummarySubjectsPage extends StatelessWidget {
  const SummarySubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ServiceSubjectsPage(
      title: 'اختر مادة للملخصات',
      onSelect: (subject) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectSummariesPage(
              subject: subject,
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// اختيار المادة للاختبارات
// =====================================================

class QuizSubjectsPage extends StatelessWidget {
  const QuizSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _ServiceSubjectsPage(
      title: 'اختر مادة للاختبار',
      onSelect: (subject) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectQuizPage(
              subject: subject,
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// قائمة المواد المستخدمة في الخدمات
// =====================================================

class _ServiceSubjectsPage extends StatefulWidget {
  final String title;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _ServiceSubjectsPage({
    required this.title,
    required this.onSelect,
  });

  @override
  State<_ServiceSubjectsPage> createState() =>
      _ServiceSubjectsPageState();
}

class _ServiceSubjectsPageState
    extends State<_ServiceSubjectsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadSubjects();
  }

  Future<List<Map<String, dynamic>>> loadSubjects() async {
    final result = await db
        .from('subjects')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: errorText(snapshot.error!),
              onRetry: () {
                setState(() => future = loadSubjects());
              },
            );
          }

          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return const _EmptyContent(
              message: 'لا توجد مواد متاحة حاليًا.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final name = '${subject['name'] ?? 'مادة'}';

              return Card(
                color: panel,
                child: ListTile(
                  leading: Icon(
                    Icons.school_outlined,
                    color: subjectColor(name),
                  ),
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => widget.onSelect(subject),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// صفحة الإشعارات
// =====================================================

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadNotifications();
  }

  Future<List<Map<String, dynamic>>> loadNotifications() async {
    final result = await db
        .from('notifications')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () {
              setState(() => future = loadNotifications());
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: errorText(snapshot.error!),
              onRetry: () {
                setState(() => future = loadNotifications());
              },
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const _EmptyContent(
              message: 'لا توجد إشعارات حتى الآن.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];

              final title =
                  '${item['title'] ?? 'إشعار جديد'}';

              final message =
                  '${item['message'] ?? item['body'] ?? ''}';

              return Card(
                color: panel,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_outlined,
                            color: Color(0xFFF0B45B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: const TextStyle(height: 1.7),
                        ),
                      ],
                      if (item['created_at'] != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${item['created_at']}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// إرسال طلب مساعدة دون حساب طالب
// =====================================================

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  bool sending = false;

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => sending = true);

    try {
      final user = db.auth.currentUser;

      final payload = <String, dynamic>{
        'title': titleController.text.trim(),
        'message': messageController.text.trim(),
        'status': 'pending',
      };

      // لا نطلب حسابًا من الطالب.
      // إذا كان هناك مستخدم مسجل يمكن ربط الطلب بحسابه.
      if (user != null) {
        payload['user_id'] = user.id;
      }

      // يتطلب هذا الإدخال أن تسمح قاعدة البيانات
      // بالطلبات المجهولة وسياسة INSERT المناسبة.
      await db.from('admin_requests').insert(payload);

      if (!mounted) return;

      titleController.clear();
      messageController.clear();

      showMessage(
        context,
        'تم إرسال الطلب بنجاح.',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        context,
        'تعذر إرسال الطلب: ${errorText(e)}',
      );
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب مساعدة'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: 56,
              color: Color(0xFFF06472),
            ),
            const SizedBox(height: 12),
            const Text(
              'كيف يمكننا مساعدتك؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اكتب طلبك وسيصل إلى لوحة الإدارة عند إعداد قاعدة البيانات بالشكل الصحيح.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'اسمك (اختياري)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الطلب',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اكتب عنوان الطلب.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: messageController,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'تفاصيل الطلب',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.message_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اكتب تفاصيل طلبك.';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: sending ? null : sendRequest,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                sending ? 'جارٍ الإرسال...' : 'إرسال الطلب',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// =====================================================
// دخول الإدارة
// =====================================================

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final nameController = TextEditingController();
  final codeController = TextEditingController();

  bool loading = false;
  bool obscureCode = true;

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (nameController.text.trim() != 'برهان' ||
        codeController.text != 'kanojo') {
      showMessage(context, 'اسم المدير أو الرمز غير صحيح.');
      return;
    }

    setState(() => loading = true);

    try {
      // لا يمنح هذا الفحص وحده صلاحيات قاعدة البيانات.
      // يجب أن يكون الوصول الإداري محميًا أيضًا بسياسات Supabase.
      final user = db.auth.currentUser;

      if (user == null) {
        showMessage(
          context,
          'تم قبول البيانات، لكن يلزم إعداد حساب مدير موثّق في Supabase قبل فتح لوحة الإدارة.',
        );
        return;
      }

      final profile = await db
          .from('profiles')
          .select('role, username, full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null || profile['role'] != 'admin') {
        showMessage(
          context,
          'هذا الحساب ليس حساب مدير. تحقق من profiles.role في Supabase.',
        );
        return;
      }

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
    } catch (e) {
      if (mounted) {
        showMessage(context, 'تعذر التحقق: ${errorText(e)}');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول الإدارة')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 75,
                  color: Color(0xFFB7BAC3),
                ),
                const SizedBox(height: 18),
                const Text(
                  'لوحة الإدارة',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المدير',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: codeController,
                  obscureText: obscureCode,
                  decoration: InputDecoration(
                    labelText: 'رمز الإدارة',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => obscureCode = !obscureCode);
                      },
                      icon: Icon(
                        obscureCode
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => login(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text('دخول'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'يتطلب فتح لوحة الإدارة حسابًا موثّقًا بصلاحية admin في Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// لوحة تحكم الإدارة
// =====================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int tab = 0;

  final titles = const [
    'إدارة الدروس',
    'إدارة الملخصات',
    'إدارة الأسئلة',
    'طلبات الطلاب',
  ];

  Future<void> logout() async {
    // لا نسجل الخروج من حساب الطالب؛ تبقى جلسة Auth للإدارة.
    await db.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab]),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: const [
          AdminContentPage(type: 'lessons'),
          AdminContentPage(type: 'summaries'),
          AdminContentPage(type: 'questions'),
          AdminRequestsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) {
          setState(() => tab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'الدروس',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize_outlined),
            label: 'الملخصات',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            label: 'الأسئلة',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            label: 'الطلبات',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// إضافة وحذف الدروس والملخصات والأسئلة
// =====================================================

class AdminContentPage extends StatefulWidget {
  final String type;

  const AdminContentPage({
    super.key,
    required this.type,
  });

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadItems();
  }

  String get tableName {
    if (widget.type == 'lessons') return 'lessons';
    if (widget.type == 'summaries') return 'summaries';
    return 'questions';
  }

  String get pageTitle {
    if (widget.type == 'lessons') return 'الدروس';
    if (widget.type == 'summaries') return 'الملخصات';
    return 'الأسئلة';
  }

  Future<List<Map<String, dynamic>>> loadItems() async {
    final result = await db
        .from(tableName)
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> loadSubjects() async {
    final result = await db
        .from('subjects')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> refreshItems() async {
    setState(() => future = loadItems());
  }

  Future<void> addItem() async {
    try {
      final subjects = await loadSubjects();

      if (!mounted) return;

      if (subjects.isEmpty) {
        showMessage(context, 'لا توجد مواد فعالة في قاعدة البيانات.');
        return;
      }

      final result = await showDialog<bool>(
        context: context,
        builder: (_) => _AdminEditorDialog(
          type: widget.type,
          subjects: subjects,
        ),
      );

      if (result == true) {
        await refreshItems();
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'تعذر فتح النموذج: ${errorText(e)}');
      }
    }
  }

  Future<void> deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف "${item['title'] ?? 'هذا العنصر'}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await db.from(tableName).delete().eq('id', item['id']);

      if (!mounted) return;

      showMessage(context, 'تم حذف العنصر.');
      await refreshItems();
    } catch (e) {
      if (mounted) {
        showMessage(context, 'فشل الحذف: ${errorText(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addItem,
        icon: const Icon(Icons.add),
        label: Text('إضافة ${pageTitle.substring(0, pageTitle.length - 1)}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: errorText(snapshot.error!),
              onRetry: refreshItems,
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return _EmptyContent(
              message: 'لا توجد ${pageTitle} مضافة حتى الآن.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final published = item['is_published'] == true;

              return Card(
                color: panel,
                child: ListTile(
                  title: Text(
                    '${item['title'] ?? item['question_text'] ?? 'عنصر'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    published ? 'منشور' : 'غير منشور',
                    style: TextStyle(
                      color: published
                          ? const Color(0xFF55B7A5)
                          : muted,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'حذف',
                    onPressed: () => deleteItem(item),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFF06472),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================
// نموذج إضافة المحتوى
// =====================================================

class _AdminEditorDialog extends StatefulWidget {
  final String type;
  final List<Map<String, dynamic>> subjects;

  const _AdminEditorDialog({
    required this.type,
    required this.subjects,
  });

  @override
  State<_AdminEditorDialog> createState() =>
      _AdminEditorDialogState();
}

class _AdminEditorDialogState extends State<_AdminEditorDialog> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final questionController = TextEditingController();

  final optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  String? subjectId;
  int correctIndex = 0;
  bool publish = true;
  bool saving = false;

  bool get isQuestion => widget.type == 'questions';

  String get contentType {
    if (widget.type == 'lessons') return 'درس';
    if (widget.type == 'summaries') return 'ملخص';
    return 'سؤال';
  }

  @override
  void initState() {
    super.initState();
    subjectId = widget.subjects.first['id'].toString();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    questionController.dispose();

    for (final controller in optionControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final common = <String, dynamic>{
        'subject_id': subjectId,
        'is_published': publish,
      };

      if (widget.type == 'lessons' ||
          widget.type == 'summaries') {
        final payload = <String, dynamic>{
          ...common,
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
        };

        await db.from(widget.type).insert(payload);
      } else {
        final question = await db
            .from('questions')
            .insert({
              ...common,
              'title': titleController.text.trim(),
              'question_text': questionController.text.trim(),
            })
            .select('id')
            .single();

        final questionId = question['id'];

        final optionPayload = <Map<String, dynamic>>[];

        for (int i = 0; i < optionControllers.length; i++) {
          optionPayload.add({
            'question_id': questionId,
            'option_text': optionControllers[i].text.trim(),
            'is_correct': i == correctIndex,
          });
        }

        await db.from('question_options').insert(optionPayload);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
      showMessage(context, 'تمت إضافة $contentType.');
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          'تعذرت الإضافة: ${errorText(e)}',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة $contentType'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: subjectId,
                  decoration: const InputDecoration(
                    labelText: 'المادة',
                  ),
                  items: widget.subjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject['id'].toString(),
                      child: Text('${subject['name'] ?? 'مادة'}'),
                    );
                  }).toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() => subjectId = value);
                        },
                  validator: (value) =>
                      value == null ? 'اختر المادة' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: isQuestion
                        ? 'عنوان السؤال (اختياري)'
                        : 'عنوان $contentType',
                  ),
                  validator: (value) {
                    if (!isQuestion &&
                        (value == null || value.trim().isEmpty)) {
                      return 'اكتب العنوان';
                    }
                    return null;
                  },
                ),
                if (isQuestion) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: questionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'نص السؤال',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'اكتب نص السؤال';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الخيارات — اختر الإجابة الصحيحة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < 4; i++)
                    Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: correctIndex,
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => correctIndex = value);
                                  }
                                },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: optionControllers[i],
                            decoration: InputDecoration(
                              labelText: 'الخيار ${i + 1}',
                            ),
                            validator: (value) {
                              if (isQuestion &&
                                  (value == null ||
                                      value.trim().isEmpty)) {
                                return 'اكتب الخيار';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                ] else ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentController,
                    minLines: 5,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: 'محتوى $contentType',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'اكتب المحتوى';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('نشر مباشرة'),
                  value: publish,
                  onChanged: saving
                      ? null
                      : (value) {
                          setState(() => publish = value);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

// =====================================================
// عرض طلبات الطلاب وتحديث حالتها
// =====================================================

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() =>
      _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = loadRequests();
  }

  Future<List<Map<String, dynamic>>> loadRequests() async {
    final result = await db
        .from('admin_requests')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> refreshRequests() async {
    setState(() => future = loadRequests());
  }

  Future<void> updateStatus(
    Map<String, dynamic> request,
    String status,
  ) async {
    try {
      await db
          .from('admin_requests')
          .update({'status': status})
          .eq('id', request['id']);

      if (!mounted) return;

      showMessage(context, 'تم تحديث حالة الطلب.');
      await refreshRequests();
    } catch (e) {
      if (mounted) {
        showMessage(context, 'تعذر التحديث: ${errorText(e)}');
      }
    }
  }

  String statusLabel(String? status) {
    switch (status) {
      case 'in_progress':
        return 'قيد المعالجة';
      case 'completed':
        return 'مكتمل';
      default:
        return 'قيد الانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ErrorView(
            message: errorText(snapshot.error!),
            onRetry: refreshRequests,
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const _EmptyContent(
            message: 'لا توجد طلبات من الطلاب حتى الآن.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final status = '${request['status'] ?? 'pending'}';

            return Card(
              color: panel,
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request['title'] ?? 'طلب مساعدة'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${request['message'] ?? ''}',
                      style: const TextStyle(height: 1.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الحالة: ${statusLabel(status)}',
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => updateStatus(
                            request,
                            'pending',
                          ),
                          child: const Text('قيد الانتظار'),
                        ),
                        OutlinedButton(
                          onPressed: () => updateStatus(
                            request,
                            'in_progress',
                          ),
                          child: const Text('قيد المعالجة'),
                        ),
                        FilledButton(
                          onPressed: () => updateStatus(
                            request,
                            'completed',
                          ),
                          child: const Text('مكتمل'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}