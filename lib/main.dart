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

String internalEmail(String username) =>
    '${username.trim().toLowerCase()}@users.alburahei.app';

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
            borderSide: const BorderSide(color: Color(0xFF34363D)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF34363D)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB7BAC3)),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// =====================================================
// بوابة تسجيل الدخول
// =====================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (db.auth.currentSession == null) {
          return const LoginPage();
        }
        return const HomePage();
      },
    );
  }
}

// =====================================================
// تسجيل الدخول وإنشاء حساب الطالب
// =====================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final fullName = TextEditingController();
  final password = TextEditingController();

  bool signup = false;
  bool busy = false;
  bool hidePassword = true;

  @override
  void dispose() {
    username.dispose();
    fullName.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final name = username.text.trim().toLowerCase();
    setState(() => busy = true);

    try {
      if (signup) {
        await db.auth.signUp(
          email: internalEmail(name),
          password: password.text,
          data: {
            'username': name,
            'full_name': fullName.text.trim().isEmpty
                ? name
                : fullName.text.trim(),
          },
        );

        if (!mounted) return;

        showMessage(
          context,
          'تم إرسال طلب إنشاء الحساب. إذا لم تدخل تلقائيًا، فقد تحتاج إلى تعطيل تأكيد البريد في إعدادات Supabase.',
        );
      } else {
        await db.auth.signInWithPassword(
          email: internalEmail(name),
          password: password.text,
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'تعذر إكمال العملية: ${errorText(e)}');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFF292B31),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.school_rounded, size: 44),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'البريهي التعليمي',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'تعلّم، راجع، واختبر فهمك',
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 30),
                    if (signup) ...[
                      TextFormField(
                        controller: fullName,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: username,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (!RegExp(r'^[a-zA-Z0-9_.-]{3,24}$')
                            .hasMatch(value)) {
                          return 'استخدم 3 إلى 24 حرفًا إنجليزيًا أو رقمًا أو . _ -';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: password,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => hidePassword = !hidePassword);
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: busy ? null : submit,
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(signup ? 'إنشاء حساب' : 'تسجيل الدخول'),
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => signup = !signup),
                      child: Text(
                        signup
                            ? 'لديك حساب؟ سجّل الدخول'
                            : 'ليس لديك حساب؟ أنشئ حسابًا',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// الصفحة الرئيسية والتنقل بين النوافذ
// =====================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> subjectsFuture;

  bool admin = false;
  Map<String, dynamic>? profile;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    subjectsFuture = loadSubjects();
    loadProfile();
  }

  Future<List<Map<String, dynamic>>> loadSubjects() async {
    final rows = await db
        .from('subjects')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> loadProfile() async {
    try {
      final user = db.auth.currentUser;
      if (user == null) return;

      final row = await db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          profile = row;
          admin = row?['role'] == 'admin';
        });
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          'تعذر تحميل الملف الشخصي: ${errorText(e)}',
        );
      }
    }
  }

  Future<void> signOut() async {
    await db.auth.signOut();
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'admin') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminPage(
                      initiallyAdmin: admin,
                      onActivated: loadProfile,
                    ),
                  ),
                );
                await loadProfile();
              } else if (value == 'refresh') {
                setState(() => subjectsFuture = loadSubjects());
              } else if (value == 'logout') {
                await signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'admin',
                child: Text(admin ? 'لوحة المدير' : 'تفعيل المدير'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('تحديث المواد'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('تسجيل الخروج'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          SubjectsPage(
            subjectsFuture: subjectsFuture,
            fullName: '${profile?['full_name'] ?? ''}',
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
        onDestinationSelected: (i) => setState(() => tab = i),
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
  final String fullName;
  final VoidCallback onRetry;

  const SubjectsPage({
    super.key,
    required this.subjectsFuture,
    required this.fullName,
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
          return const Center(child: CircularProgressIndicator());
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
                    colors: [Color(0xFF303139), Color(0xFF191A1E)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رحلتك نحو المعرفة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName.isEmpty
                          ? 'اختر مادتك وابدأ التعلم'
                          : 'أهلًا $fullName، اختر مادتك',
                      style: const TextStyle(color: muted, fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'تعلّم  •  لخّص  •  اختبر نفسك',
                      style: TextStyle(color: Color(0xFFD1D2D7)),
                    ),
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
                  child: Text('لا توجد مواد نشطة في قاعدة البيانات.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final row = rows[i];
                      final name = '${row['name'] ?? 'مادة'}';
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
                                builder: (_) =>
                                    SubjectLessonsPage(subject: row),
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
// قائمة دروس المادة
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
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> lessons = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadLessons();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadLessons() async {
    try {
      final result = await db
          .from('lessons')
          .select()
          .eq('subject_id', widget.subject['id'])
          .eq('is_published', true)
          .order('created_at');

      if (!mounted) return;

      setState(() {
        lessons = List<Map<String, dynamic>>.from(result);
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = subjectColors[widget.subject['name']] ??
        const Color(0xFFB54A55);

    final query = searchController.text.trim().toLowerCase();

    final filtered = lessons.where((lesson) {
      final title = (lesson['title'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject['name']?.toString() ?? 'الدروس'),
        backgroundColor: color.withOpacity(0.12),
      ),
      body: RefreshIndicator(
        onRefresh: loadLessons,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث عن درس...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error.isNotEmpty)
              ErrorView(message: error, onRetry: loadLessons)
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'لا توجد دروس منشورة هنا حتى الآن.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...filtered.map(
                (lesson) => LessonTile(
                  lesson: lesson,
                  color: color,
                  subject: widget.subject,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// بطاقة الدرس
// =====================================================

class LessonTile extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final Map<String, dynamic> subject;
  final Color color;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.subject,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(Icons.menu_book_rounded, color: color),
        ),
        title: Text(
          '${lesson['title'] ?? 'درس بلا عنوان'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 7),
          child: Text('اضغط لفتح الدرس'),
        ),
        trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonDetailPage(
                lesson: lesson,
                subject: subject,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// صفحة قراءة الدرس
// =====================================================

class LessonDetailPage extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final Map<String, dynamic> subject;

  const LessonDetailPage({
    super.key,
    required this.lesson,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final content = (lesson['content'] ??
            lesson['body'] ??
            lesson['lesson_text'] ??
            'لم تتم إضافة محتوى لهذا الدرس بعد.')
        .toString();

    final color = subjectColor('${subject['name'] ?? ''}');

    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson['title'] ?? 'الدرس'}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subject['name'] ?? ''}',
                  style: TextStyle(color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  '${lesson['title'] ?? 'الدرس'}',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(
              content,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 17,
                height: 1.9,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectSummariesPage(
                    subject: subject,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notes_rounded),
            label: const Text('الانتقال إلى ملخصات المادة'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectQuizPage(
                    subject: subject,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('اختبر نفسك'),
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

class _SubjectSummariesPageState extends State<SubjectSummariesPage> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> summaries = [];

  @override
  void initState() {
    super.initState();
    loadSummaries();
  }

  Future<void> loadSummaries() async {
    try {
      final result = await db
          .from('summaries')
          .select()
          .eq('subject_id', widget.subject['id'])
          .eq('is_published', true)
          .order('created_at');

      if (!mounted) return;

      setState(() {
        summaries = List<Map<String, dynamic>>.from(result);
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملخصات المادة')),
      body: RefreshIndicator(
        onRefresh: loadSummaries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error.isNotEmpty)
              ErrorView(message: error, onRetry: loadSummaries)
            else if (summaries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'لا توجد ملخصات منشورة لهذه المادة حتى الآن.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...summaries.map(
                (summary) => Card(
                  color: panel,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFFB7BAC3),
                    ),
                    title: Text(
                      '${summary['title'] ?? 'ملخص'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('اضغط لقراءة الملخص'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReadingPage(
                            title: '${summary['title'] ?? 'ملخص'}',
                            content: (summary['content'] ??
                                    summary['body'] ??
                                    summary['summary_text'] ??
                                    'لم تتم إضافة محتوى.')
                                .toString(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ReadingPage extends StatelessWidget {
  final String title;
  final String content;

  const ReadingPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
          ),
          child: SelectableText(
            content,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 17, height: 1.9),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// الاختبارات
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
  String error = '';
  List<Map<String, dynamic>> questions = [];
  List<List<Map<String, dynamic>>> options = [];
  final Map<int, String> answers = {};
  bool finished = false;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final rows = await db
          .from('questions')
          .select()
          .eq('subject_id', widget.subject['id'])
          .eq('is_published', true);

      final loadedQuestions =
          List<Map<String, dynamic>>.from(rows);

      final loadedOptions = <List<Map<String, dynamic>>>[];

      for (final question in loadedQuestions) {
        final optionRows = await db
            .from('question_options')
            .select()
            .eq('question_id', question['id']);

        loadedOptions.add(
          List<Map<String, dynamic>>.from(optionRows),
        );
      }

      if (!mounted) return;

      setState(() {
        questions = loadedQuestions;
        options = loadedOptions;
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = errorText(e);
      });
    }
  }

  String questionText(Map<String, dynamic> q) =>
      '${q['question_text'] ?? q['question'] ?? q['text'] ?? q['title'] ?? 'السؤال'}';

  String optionText(Map<String, dynamic> o) =>
      '${o['option_text'] ?? o['text'] ?? o['label'] ?? o['value'] ?? ''}';

  String optionValue(Map<String, dynamic> o) =>
      '${o['id']}';

  bool isCorrect(Map<String, dynamic> option) {
    final value = option['is_correct'];
    return value == true || value == 1 || value == 'true';
  }

  int get score {
    int result = 0;

    for (int i = 0; i < questions.length; i++) {
      final selected = answers[i];

      if (selected == null || i >= options.length) continue;

      final chosen = options[i].where(
        (o) => optionValue(o) == selected,
      );

      if (chosen.isNotEmpty && isCorrect(chosen.first)) {
        result++;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = questions.isEmpty
        ? 0
        : (score * 100 / questions.length).round();

    return Scaffold(
      appBar: AppBar(title: const Text('اختبر نفسك')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? ErrorView(message: error, onRetry: loadQuestions)
              : questions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'لا توجد أسئلة منشورة لهذه المادة.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : finished
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  size: 76,
                                  color: Color(0xFFD4A04D),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'انتهى الاختبار',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'إجابات صحيحة: $score من ${questions.length}',
                                ),
                                const SizedBox(height: 22),
                                FilledButton(
                                  onPressed: () {
                                    setState(() {
                                      answers.clear();
                                      finished = false;
                                    });
                                  },
                                  child: const Text('إعادة الاختبار'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              '${widget.subject['name'] ?? 'المادة'}',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أجب عن الأسئلة ثم اعرض نتيجتك. '
                              'عدد الأسئلة: ${questions.length}',
                              style: const TextStyle(color: muted),
                            ),
                            const SizedBox(height: 18),
                            for (int i = 0; i < questions.length; i++)
                              Card(
                                color: panel,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. ${questionText(questions[i])}',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (i < options.length)
                                        ...options[i].map(
                                          (option) => RadioListTile<String>(
                                            contentPadding: EdgeInsets.zero,
                                            value: optionValue(option),
                                            groupValue: answers[i],
                                            title: Text(optionText(option)),
                                            onChanged: (value) {
                                              if (value == null) return;
                                              setState(() {
                                                answers[i] = value;
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            FilledButton(
                              onPressed: () {
                                if (answers.length < questions.length) {
                                  showMessage(
                                    context,
                                    'أجب عن جميع الأسئلة قبل عرض النتيجة.',
                                  );
                                  return;
                                }
                                setState(() => finished = true);
                              },
                              child: const Text('إنهاء الاختبار وعرض النسبة'),
                            ),
                          ],
                        ),
    );
  }
}

// =====================================================
// الخدمات
// =====================================================

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'الخدمات',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'يمكنك متابعة الإشعارات وإرسال طلباتك إلى الإدارة.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        ServiceCard(
          icon: Icons.notifications_active_outlined,
          title: 'الإشعارات',
          subtitle: 'آخر التنبيهات والتحديثات',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsPage(),
              ),
            );
          },
        ),
        ServiceCard(
          icon: Icons.support_agent_rounded,
          title: 'طلب مساعدة',
          subtitle: 'أرسل استفسارًا أو مشكلة إلى الإدارة',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RequestPage(),
              ),
            );
          },
        ),
        ServiceCard(
          icon: Icons.notes_rounded,
          title: 'ملخصات المواد',
          subtitle: 'اختر المادة لعرض ملخصاتها',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SummarySubjectsPage(),
              ),
            );
          },
        ),
        ServiceCard(
          icon: Icons.quiz_outlined,
          title: 'الاختبارات',
          subtitle: 'اختر مادة وابدأ اختبارًا',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QuizSubjectsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// =====================================================
// اختيار مادة للملخصات
// =====================================================

class SummarySubjectsPage extends StatefulWidget {
  const SummarySubjectsPage({super.key});

  @override
  State<SummarySubjectsPage> createState() =>
      _SummarySubjectsPageState();
}

class _SummarySubjectsPageState extends State<SummarySubjectsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = fetchSubjects();
  }

  Future<List<Map<String, dynamic>>> fetchSubjects() async {
    final rows = await db
        .from('subjects')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملخصات المواد')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: errorText(snapshot.error!),
              onRetry: () => setState(() => future = fetchSubjects()),
            );
          }

          final subjects = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: subjects
                .map(
                  (subject) => ServiceCard(
                    icon: Icons.menu_book_rounded,
                    title: '${subject['name'] ?? 'مادة'}',
                    subtitle: 'عرض الملخصات',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SubjectSummariesPage(subject: subject),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// =====================================================
// اختيار مادة للاختبارات
// =====================================================

class QuizSubjectsPage extends StatefulWidget {
  const QuizSubjectsPage({super.key});

  @override
  State<QuizSubjectsPage> createState() => _QuizSubjectsPageState();
}

class _QuizSubjectsPageState extends State<QuizSubjectsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = fetchSubjects();
  }

  Future<List<Map<String, dynamic>>> fetchSubjects() async {
    final rows = await db
        .from('subjects')
        .select()
        .eq('is_active', true)
        .order('display_order');

    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبارات المواد')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: errorText(snapshot.error!),
              onRetry: () => setState(() => future = fetchSubjects()),
            );
          }

          final subjects = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: subjects
                .map(
                  (subject) => ServiceCard(
                    icon: Icons.quiz_outlined,
                    title: '${subject['name'] ?? 'مادة'}',
                    subtitle: 'ابدأ الاختبار',
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
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// =====================================================
// الإشعارات
// =====================================================

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final rows = await db
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      if (!mounted) return;

      setState(() {
        notifications = List<Map<String, dynamic>>.from(rows);
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? ErrorView(
                  message: error,
                  onRetry: loadNotifications,
                )
              : notifications.isEmpty
                  ? const Center(child: Text('لا توجد إشعارات حاليًا.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, i) {
                        final n = notifications[i];

                        return Card(
                          color: panel,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_outlined,
                            ),
                            title: Text(
                              '${n['title'] ?? 'إشعار جديد'}',
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Text(
                                '${n['message'] ?? n['content'] ?? ''}',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// =====================================================
// إرسال طلب إلى الإدارة
// =====================================================

class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  bool busy = false;

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      showMessage(context, 'اكتب عنوان الطلب وتفاصيله أولًا.');
      return;
    }

    final user = db.auth.currentUser;

    if (user == null) {
      showMessage(context, 'سجّل الدخول أولًا.');
      return;
    }

    setState(() => busy = true);

    try {
      await db.from('admin_requests').insert({
        'user_id': user.id,
        'title': title,
        'message': message,
        'status': 'pending',
      });

      if (!mounted) return;

      titleController.clear();
      messageController.clear();

      showMessage(context, 'تم إرسال طلبك إلى الإدارة.');
    } catch (e) {
      if (mounted) {
        showMessage(context, 'تعذر إرسال الطلب: ${errorText(e)}');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب مساعدة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'كيف يمكننا مساعدتك؟',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'اكتب طلبك بوضوح وسيتم حفظه في قاعدة البيانات.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الطلب',
              prefixIcon: Icon(Icons.subject),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: messageController,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: 'تفاصيل الطلب',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : sendRequest,
            icon: const Icon(Icons.send_rounded),
            label: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(busy ? 'جارٍ الإرسال...' : 'إرسال الطلب'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// الإعدادات
// =====================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = db.auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Card(
          color: panel,
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline),
            ),
            title: const Text('الحساب الحالي'),
            subtitle: Text(user?.email ?? 'لا يوجد حساب'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: panel,
          child: const ListTile(
            leading: Icon(Icons.school_outlined),
            title: Text('البريهي التعليمي'),
            subtitle: Text('تعلّم، راجع، واختبر فهمك'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: panel,
          child: ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await db.auth.signOut();
            },
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'مع تحياتي برهان البريهي',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
      ],
    );
  }
}

// =====================================================
// واجهة عامة لعرض الخطأ وإعادة المحاولة
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
// صفحة تفعيل المدير
// =====================================================

class AdminPage extends StatefulWidget {
  final bool initiallyAdmin;
  final Future<void> Function()? onActivated;

  const AdminPage({
    super.key,
    this.initiallyAdmin = false,
    this.onActivated,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController codeController = TextEditingController();

  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();

    if (widget.initiallyAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await widget.onActivated?.call();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> activateAdmin() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      setState(() => error = 'أدخل رمز المدير أولًا.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      await db.rpc(
        'activate_admin',
        params: {'entered_code': code},
      );

      final user = db.auth.currentUser;

      if (user == null) {
        throw Exception('انتهت جلسة الدخول. سجّل الدخول مجددًا.');
      }

      final profile = await db
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null || profile['role'] != 'admin') {
        throw Exception(
          'لم يتم تفعيل صلاحيات المدير لهذا الحساب.',
        );
      }

      if (!mounted) return;

      await widget.onActivated?.call();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'تعذر تفعيل لوحة المدير:\n${errorText(e)}';
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول المدير')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              color: panel,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 68,
                      color: Color(0xFFB7BAC3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لوحة إدارة التطبيق',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'أدخل رمز المدير المرتبط بقاعدة البيانات.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: codeController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'رمز المدير',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        error,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : activateAdmin,
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('تفعيل لوحة المدير'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// =====================================================
// لوحة المدير الرئيسية
// =====================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedTab = 0;

  final pages = const [
    AdminContentPage(contentType: 'lessons'),
    AdminContentPage(contentType: 'summaries'),
    AdminContentPage(contentType: 'questions'),
    AdminRequestsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المدير'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await db.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedTab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (i) {
          setState(() => selectedTab = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'الدروس',
          ),
          NavigationDestination(
            icon: Icon(Icons.notes_outlined),
            label: 'الملخصات',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            label: 'الأسئلة',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            label: 'الطلبات',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// إضافة الدروس والملخصات والأسئلة
// =====================================================

class AdminContentPage extends StatefulWidget {
  final String contentType;

  const AdminContentPage({
    super.key,
    required this.contentType,
  });

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final questionController = TextEditingController();
  final option1Controller = TextEditingController();
  final option2Controller = TextEditingController();
  final option3Controller = TextEditingController();
  final option4Controller = TextEditingController();

  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> entries = [];

  String? selectedSubjectId;
  int correctOption = 0;

  bool loading = true;
  bool saving = false;
  String error = '';

  bool get isQuestion => widget.contentType == 'questions';
  bool get isSummary => widget.contentType == 'summaries';

  String get tableName => widget.contentType;

  String get pageTitle {
    if (isQuestion) return 'إدارة الأسئلة';
    if (isSummary) return 'إدارة الملخصات';
    return 'إدارة الدروس';
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    option3Controller.dispose();
    option4Controller.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final subjectRows = await db
          .from('subjects')
          .select()
          .order('display_order');

      final contentRows = await db
          .from(tableName)
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      if (!mounted) return;

      final loadedSubjects =
          List<Map<String, dynamic>>.from(subjectRows);

      setState(() {
        subjects = loadedSubjects;
        entries = List<Map<String, dynamic>>.from(contentRows);

        selectedSubjectId ??= loadedSubjects.isNotEmpty
            ? '${loadedSubjects.first['id']}'
            : null;

        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = errorText(e);
      });
    }
  }

  Future<void> saveContent() async {
    if (selectedSubjectId == null) {
      showMessage(context, 'أضف مادة دراسية أولًا.');
      return;
    }

    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty) {
      showMessage(context, 'أدخل عنوان المحتوى.');
      return;
    }

    if (!isQuestion && content.isEmpty) {
      showMessage(context, 'أدخل محتوى الدرس أو الملخص.');
      return;
    }

    final optionTexts = [
      option1Controller.text.trim(),
      option2Controller.text.trim(),
      option3Controller.text.trim(),
      option4Controller.text.trim(),
    ];

    if (isQuestion) {
      final question = questionController.text.trim();

      if (question.isEmpty || optionTexts.any((v) => v.isEmpty)) {
        showMessage(context, 'أدخل السؤال وجميع الخيارات الأربعة.');
        return;
      }
    }

    setState(() => saving = true);

    try {
      final payload = <String, dynamic>{
        'subject_id': selectedSubjectId,
        'title': title,
        'is_published': true,
      };

      if (isQuestion) {
        payload['question_text'] = questionController.text.trim();
      } else {
        payload['content'] = content;
      }

      final inserted = await db
          .from(tableName)
          .insert(payload)
          .select()
          .single();

      if (isQuestion) {
        final questionId = inserted['id'];

        for (int i = 0; i < optionTexts.length; i++) {
          await db.from('question_options').insert({
            'question_id': questionId,
            'option_text': optionTexts[i],
            'is_correct': i == correctOption,
          });
        }
      }

      if (!mounted) return;

      titleController.clear();
      contentController.clear();
      questionController.clear();
      option1Controller.clear();
      option2Controller.clear();
      option3Controller.clear();
      option4Controller.clear();

      setState(() => correctOption = 0);

      showMessage(context, 'تمت إضافة المحتوى بنجاح.');
      await loadData();
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          'تعذرت إضافة المحتوى: ${errorText(e)}',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteEntry(Map<String, dynamic> entry) async {
    final id = entry['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف "${entry['title'] ?? 'هذا المحتوى'}"؟',
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
      await db.from(tableName).delete().eq('id', id);

      if (!mounted) return;

      showMessage(context, 'تم حذف المحتوى.');
      await loadData();
    } catch (e) {
      if (mounted) {
        showMessage(context, 'تعذر الحذف: ${errorText(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : error.isNotEmpty
            ? ErrorView(message: error, onRetry: loadData)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    pageTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يمكنك إضافة محتوى جديد أو حذف المحتوى الموجود.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 18),

                  // اختيار المادة
                  DropdownButtonFormField<String>(
                    value: selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'المادة الدراسية',
                    ),
                    items: subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: '${subject['id']}',
                        child: Text('${subject['name'] ?? 'مادة'}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedSubjectId = value);
                    },
                  ),

                  const SizedBox(height: 14),

                  // عنوان المحتوى
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: isQuestion
                          ? 'عنوان مجموعة الأسئلة'
                          : 'عنوان المحتوى',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // حقول الأسئلة وخيارات الإجابة
                  if (isQuestion) ...[
                    TextField(
                      controller: questionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'نص السؤال',
                      ),
                    ),

                    const SizedBox(height: 12),

                    for (final item in [
                      option1Controller,
                      option2Controller,
                      option3Controller,
                      option4Controller,
                    ].asMap().entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: item.value,
                          decoration: InputDecoration(
                            labelText: 'الخيار ${item.key + 1}',
                          ),
                        ),
                      ),

                    const SizedBox(height: 4),
                    const Text('حدد الإجابة الصحيحة:'),
                    const SizedBox(height: 6),

                    Column(
                      children: List.generate(
                        4,
                        (i) => RadioListTile<int>(
                          groupValue: correctOption,
                          value: i,
                          title: Text('الخيار ${i + 1}'),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => correctOption = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    // يظهر للدرس والملخص فقط، وليس للسؤال
                    TextField(
                      controller: contentController,
                      minLines: 5,
                      maxLines: 12,
                      decoration: InputDecoration(
                        labelText: isSummary
                            ? 'نص الملخص'
                            : 'نص الدرس',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : saveContent,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          saving ? 'جارٍ الحفظ...' : 'إضافة المحتوى',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    'المحتوى الحالي',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (entries.isEmpty)
                    const Text('لا يوجد محتوى مضاف حتى الآن.')
                  else
                    ...entries.map(
                      (entry) => Card(
                        color: panel,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(
                            '${entry['title'] ?? 'بلا عنوان'}',
                          ),
                          subtitle: Text(
                            'معرّف المحتوى: ${entry['id']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'حذف',
                            onPressed: () => deleteEntry(entry),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
  }
}

// =====================================================
// طلبات الطلاب للإدارة
// =====================================================

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> requests = [];

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      final rows = await db
          .from('admin_requests')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      if (!mounted) return;

      setState(() {
        requests = List<Map<String, dynamic>>.from(rows);
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = errorText(e);
      });
    }
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
      await loadRequests();
    } catch (e) {
      if (mounted) {
        showMessage(context, 'تعذر تحديث الطلب: ${errorText(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return ErrorView(message: error, onRetry: loadRequests);
    }

    if (requests.isEmpty) {
      return const Center(
        child: Text('لا توجد طلبات من الطلاب حاليًا.'),
      );
    }

    return RefreshIndicator(
      onRefresh: loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, i) {
          final request = requests[i];

          return Card(
            color: panel,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request['title'] ?? 'طلب بلا عنوان'}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${request['message'] ?? 'لا توجد تفاصيل'}',
                    style: const TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'الحالة: ${request['status'] ?? 'غير محددة'}',
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
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
                        child: const Text('تم الحل'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}