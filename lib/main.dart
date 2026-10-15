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
        showMessage(
          context,
          'تعذر إكمال العملية: ${errorText(e)}',
        );
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
                      child: const Icon(
                        Icons.school_rounded,
                        size: 44,
                      ),
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

                        if (!RegExp(
                          r'^[a-zA-Z0-9_.-]{3,24}$',
                        ).hasMatch(value)) {
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
                            setState(() {
                              hidePassword = !hidePassword;
                            });
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
                            : Text(
                                signup ? 'إنشاء حساب' : 'تسجيل الدخول',
                              ),
                      ),
                    ),

                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              setState(() => signup = !signup);
                            },
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
                setState(() {
                  subjectsFuture = loadSubjects();
                });
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
              setState(() {
                subjectsFuture = loadSubjects();
              });
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
// عرض المواد الدراسية من Supabase
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
                      style: const TextStyle(
                        color: muted,
                        fontSize: 15,
                      ),
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
                  child: Text(
                    'لا توجد مواد نشطة في قاعدة البيانات.',
                  ),
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
                                builder: (_) => SubjectLessonsPage(
                                  subject: row,
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
  final TextEditingController searchController =
      TextEditingController();

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
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = subjectColors[widget.subject['name']] ??
        const Color(0xFFB54A55);

    final query = searchController.text.trim().toLowerCase();

    final filtered = lessons.where((lesson) {
      final title =
          (lesson['title'] ?? '').toString().toLowerCase();
      return title.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject['name'] ?? 'الدروس'),
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
              ErrorView(
                message: error,
                onRetry: loadLessons,
              )
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.menu_book, color: color),
        ),
        title: Text(
          lesson['title']?.toString() ?? 'درس بدون عنوان',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('اضغط لفتح الدرس ومواده التعليمية'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonPage(
                lesson: lesson,
                subject: subject,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class LessonPage extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final Map<String, dynamic> subject;
  final Color color;

  const LessonPage({
    super.key,
    required this.lesson,
    required this.subject,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final lessonId = lesson['id'].toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson['title']?.toString() ?? 'الدرس'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_stories, color: color, size: 34),
                const SizedBox(height: 12),
                Text(
                  subject['name']?.toString() ?? '',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson['title']?.toString() ?? 'الدرس',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _LessonAction(
            icon: Icons.chrome_reader_mode,
            title: 'شرح الدرس',
            subtitle: 'اقرأ محتوى الدرس كاملًا',
            color: color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TextPage(
                    title: lesson['title']?.toString() ?? 'شرح الدرس',
                    content:
                        lesson['content']?.toString() ??
                        'لم تتم إضافة شرح لهذا الدرس بعد.',
                    color: color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _LessonAction(
            icon: Icons.summarize,
            title: 'ملخص الدرس',
            subtitle: 'راجع أهم المعلومات',
            color: color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LinkedContentPage(
                    lessonId: lessonId,
                    title: 'ملخصات الدرس',
                    table: 'summaries',
                    color: color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _LessonAction(
            icon: Icons.quiz,
            title: 'أسئلة الدرس',
            subtitle: 'اختبر فهمك واحصل على نتيجتك',
            color: color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizPage(
                    subjectId: subject['id'].toString(),
                    lessonId: lessonId,
                    title: 'اختبار: ${lesson['title']}',
                    color: color,
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

class _LessonAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _LessonAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}

class TextPage extends StatelessWidget {
  final String title;
  final String content;
  final Color color;

  const TextPage({
    super.key,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(
              content.trim().isEmpty
                  ? 'لم تتم إضافة محتوى بعد.'
                  : content,
              style: const TextStyle(
                fontSize: 17,
                height: 1.9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LinkedContentPage extends StatefulWidget {
  final String lessonId;
  final String title;
  final String table;
  final Color color;

  const LinkedContentPage({
    super.key,
    required this.lessonId,
    required this.title,
    required this.table,
    required this.color,
  });

  @override
  State<LinkedContentPage> createState() =>
      _LinkedContentPageState();
}

class _LinkedContentPageState extends State<LinkedContentPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      final result = await db
          .from(widget.table)
          .select()
          .eq('lesson_id', widget.lessonId)
          .eq('is_published', true)
          .order('created_at');

      if (!mounted) return;

      setState(() {
        items = List<Map<String, dynamic>>.from(result);
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? ErrorView(
                  message: error,
                  onRetry: loadItems,
                )
              : items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'لا يوجد محتوى منشور مرتبط بهذا الدرس بعد.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              Icons.article_outlined,
                              color: widget.color,
                            ),
                            title: Text(
                              item['title']?.toString() ??
                                  'ملخص بدون عنوان',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('فتح المحتوى'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TextPage(
                                    title: item['title']?.toString() ??
                                        widget.title,
                                    content:
                                        item['content']?.toString() ?? '',
                                    color: widget.color,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String subjectId;
  final String lessonId;
  final String title;
  final Color color;

  const QuizPage({
    super.key,
    required this.subjectId,
    required this.lessonId,
    required this.title,
    required this.color,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> questions = [];
  final Map<String, String> answers = {};

  bool loading = true;
  bool submitted = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    try {
      final result = await db
          .from('questions')
          .select('*, question_options(*)')
          .eq('subject_id', widget.subjectId)
          .eq('lesson_id', widget.lessonId)
          .eq('is_published', true)
          .order('created_at');

      if (!mounted) return;

      setState(() {
        questions = List<Map<String, dynamic>>.from(result);
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> optionsFor(
    Map<String, dynamic> question,
  ) {
    final raw = question['question_options'];

    if (raw is! List) return [];

    final options = List<Map<String, dynamic>>.from(raw);

    options.sort((a, b) =>
        ((a['display_order'] ?? 0) as num).compareTo(
          (b['display_order'] ?? 0) as num,
        ));

    return options;
  }

  int get correctCount {
    int count = 0;

    for (final question in questions) {
      final questionId = question['id'].toString();
      final chosen = answers[questionId];

      final options = optionsFor(question);
      final selected = options.where(
        (option) =>
            option['option_key']?.toString() == chosen &&
            option['is_correct'] == true,
      );

      if (selected.isNotEmpty) count++;
    }

    return count;
  }

  int get percentage {
    if (questions.isEmpty) return 0;
    return ((correctCount / questions.length) * 100).round();
  }

  String get resultMessage {
    if (percentage >= 90) return 'ممتاز! إتقان رائع للدرس.';
    if (percentage >= 75) return 'جيد جدًا! واصل التقدم.';
    if (percentage >= 50) return 'نتيجة جيدة، راجع بعض النقاط.';
    return 'تحتاج إلى مراجعة الدرس والمحاولة مرة أخرى.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? ErrorView(
                  message: error,
                  onRetry: loadQuestions,
                )
              : questions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'لا توجد أسئلة منشورة لهذا الدرس حتى الآن.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : submitted
                      ? _buildResult()
                      : _buildQuestions(),
    );
  }

  Widget _buildQuestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'عدد الأسئلة: ${questions.length}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final id = question['id'].toString();
          final options = optionsFor(question);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السؤال ${index + 1}',
                    style: TextStyle(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    question['question_text']?.toString() ??
                        'سؤال بدون نص',
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (options.isEmpty)
                    const Text('لا توجد خيارات لهذا السؤال.')
                  else
                    ...options.map((option) {
                      final key =
                          option['option_key']?.toString() ?? '';

                      return RadioListTile<String>(
                        value: key,
                        groupValue: answers[id],
                        activeColor: widget.color,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          option['option_text']?.toString() ?? '',
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => answers[id] = value);
                        },
                      );
                    }),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('إنهاء الاختبار وحساب النتيجة'),
          ),
          onPressed: () {
            if (answers.length < questions.length) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أجب عن جميع الأسئلة قبل إنهاء الاختبار.'),
                ),
              );
              return;
            }

            setState(() => submitted = true);
          },
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: widget.color.withOpacity(0.15),
              child: Icon(
                percentage >= 50 ? Icons.emoji_events : Icons.menu_book,
                size: 54,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'نتيجتك النهائية',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
            const SizedBox(height: 8),
            Text('الإجابات الصحيحة: $correctCount من ${questions.length}'),
            const SizedBox(height: 14),
            Text(
              resultMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, height: 1.7),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    answers.clear();
                    submitted = false;
                  });
                },
                child: const Text('إعادة الاختبار'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة إلى الدرس'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController codeController = TextEditingController();
  bool loading = false;
  String error = '';

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
        throw Exception('لم يتم تفعيل صلاحيات المدير لهذا الحساب.');
      }

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
        error = 'تعذر تفعيل لوحة المدير.\n${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => loading = false);
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
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 68,
                      color: Color(0xFFB54A55),
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
                      'أدخل رمز المدير المرتبط بقاعدة بيانات التطبيق.',
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
                      child: ElevatedButton(
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

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> signOut(BuildContext context) async {
    await db.auth.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المدير'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFB54A55).withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 42,
                  color: Color(0xFFB54A55),
                ),
                SizedBox(height: 12),
                Text(
                  'مرحبًا بك في الإدارة',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'أضف المحتوى التعليمي وعدّله وانشره للطلاب.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _AdminAction(
            icon: Icons.menu_book,
            title: 'إدارة الدروس',
            description: 'إضافة الدروس وتعديلها وحذفها ونشرها',
            onTap: () => _openManager(context, 'lessons'),
          ),
          _AdminAction(
            icon: Icons.summarize,
            title: 'إدارة الملخصات',
            description: 'ربط الملخصات بالدروس',
            onTap: () => _openManager(context, 'summaries'),
          ),
          _AdminAction(
            icon: Icons.quiz,
            title: 'إدارة الأسئلة',
            description: 'إنشاء أسئلة واختيار الإجابة الصحيحة',
            onTap: () => _openManager(context, 'questions'),
          ),
          _AdminAction(
            icon: Icons.home_outlined,
            title: 'العودة إلى التطبيق',
            description: 'العودة إلى صفحة المواد التعليمية',
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthGate(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _openManager(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentManager(type: type),
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFB54A55),
          size: 18,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(description),
        ),
        trailing: Icon(icon, color: const Color(0xFFB54A55), size: 28),
      ),
    );
  }
}

class ContentManager extends StatefulWidget {
  final String type;

  const ContentManager({
    super.key,
    required this.type,
  });

  @override
  State<ContentManager> createState() => _ContentManagerState();
}

class _ContentManagerState extends State<ContentManager> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> subjects = [];
  bool loading = true;
  String error = '';

  String get table => widget.type;

  String get pageTitle {
    switch (widget.type) {
      case 'lessons':
        return 'إدارة الدروس';
      case 'summaries':
        return 'إدارة الملخصات';
      default:
        return 'إدارة الأسئلة';
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final subjectResult = await db
          .from('subjects')
          .select()
          .order('display_order');

      final result = await db
          .from(table)
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        subjects = List<Map<String, dynamic>>.from(subjectResult);
        items = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String subjectName(dynamic subjectId) {
    for (final subject in subjects) {
      if (subject['id'].toString() == subjectId?.toString()) {
        return subject['name']?.toString() ?? 'مادة';
      }
    }
    return 'مادة غير محددة';
  }

  String itemTitle(Map<String, dynamic> item) {
    if (widget.type == 'questions') {
      return item['question_text']?.toString() ?? 'سؤال';
    }
    return item['title']?.toString() ?? 'بدون عنوان';
  }

  Future<void> deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل تريد حذف هذا المحتوى؟ لا يمكن التراجع عن الحذف.',
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
      await db.from(table).delete().eq('id', item['id']);

      if (widget.type == 'questions') {
        // خيارات السؤال تُحذف تلقائيًا إذا كان المفتاح الأجنبي
        // في قاعدة البيانات مضبوطًا على ON DELETE CASCADE.
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المحتوى.')),
      );
      await loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحذف: $e')),
      );
    }
  }

  Future<void> openEditor([Map<String, dynamic>? item]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContentEditor(
          type: widget.type,
          subjects: subjects,
          item: item,
        ),
      ),
    );

    if (saved == true) loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة محتوى'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? ErrorView(message: error, onRetry: loadData)
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(30),
                          children: const [
                            SizedBox(height: 100),
                            Icon(Icons.inventory_2_outlined, size: 55),
                            SizedBox(height: 16),
                            Center(
                              child: Text(
                                'لا يوجد محتوى حتى الآن.\nاضغط «إضافة محتوى» للبدء.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final published =
                                item['is_published'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemTitle(item),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      subjectName(item['subject_id']),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          published
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          size: 17,
                                          color: published
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          published ? 'منشور' : 'مسودة',
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'تعديل',
                                          onPressed: () => openEditor(item),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف',
                                          onPressed: () => deleteItem(item),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class ContentEditor extends StatefulWidget {
  final String type;
  final List<Map<String, dynamic>> subjects;
  final Map<String, dynamic>? item;

  const ContentEditor({
    super.key,
    required this.type,
    required this.subjects,
    this.item,
  });

  @override
  State<ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<ContentEditor> {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final questionController = TextEditingController();
  final explanationController = TextEditingController();

  final optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

  String? subjectId;
  String? lessonId;
  String correctOption = 'A';
  bool published = true;
  bool saving = false;
  bool lessonsLoading = false;

  List<Map<String, dynamic>> lessons = [];

  bool get isQuestion => widget.type == 'questions';
  bool get isLesson => widget.type == 'lessons';
  bool get isSummary => widget.type == 'summaries';
  bool get isEditing => widget.item != null;

  String get heading {
    if (isQuestion) return isEditing ? 'تعديل سؤال' : 'إضافة سؤال';
    if (isSummary) return isEditing ? 'تعديل ملخص' : 'إضافة ملخص';
    return isEditing ? 'تعديل درس' : 'إضافة درس';
  }

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    if (item != null) {
      subjectId = item['subject_id']?.toString();
      lessonId = item['lesson_id']?.toString();
      published = item['is_published'] == true;

      if (isQuestion) {
        questionController.text =
            item['question_text']?.toString() ?? '';
        explanationController.text =
            item['explanation']?.toString() ?? '';
      } else {
        titleController.text = item['title']?.toString() ?? '';
        contentController.text = item['content']?.toString() ?? '';
      }
    } else if (widget.subjects.isNotEmpty) {
      subjectId = widget.subjects.first['id'].toString();
    }

    if (isQuestion && item != null) {
      loadExistingOptions(item['id'].toString());
    }

    if (isQuestion || isSummary) {
      loadLessons();
    }
  }

  Future<void> loadExistingOptions(String questionId) async {
    try {
      final result = await db
          .from('question_options')
          .select()
          .eq('question_id', questionId);

      final options = List<Map<String, dynamic>>.from(result);

      for (final option in options) {
        final key = option['option_key']?.toString() ?? '';
        final index = const ['A', 'B', 'C', 'D'].indexOf(key);

        if (index >= 0) {
          optionControllers[index].text =
              option['option_text']?.toString() ?? '';

          if (option['is_correct'] == true) {
            correctOption = key;
          }
        }
      }

      if (mounted) setState(() {});
    } catch (_) {
      // يمكن للمستخدم إدخال الخيارات يدويًا إذا تعذر تحميلها.
    }
  }

  Future<void> loadLessons() async {
    if (subjectId == null) return;

    setState(() => lessonsLoading = true);

    try {
      final result = await db
          .from('lessons')
          .select('id, title, subject_id')
          .eq('subject_id', subjectId!)
          .order('created_at', ascending: false);

      if (!mounted) return;

      lessons = List<Map<String, dynamic>>.from(result);

      if (lessonId != null &&
          !lessons.any((lesson) => lesson['id'].toString() == lessonId)) {
        lessonId = null;
      }

      setState(() => lessonsLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => lessonsLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الدروس: $e')),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    questionController.dispose();
    explanationController.dispose();

    for (final controller in optionControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> saveContent() async {
    if (!formKey.currentState!.validate()) return;

    if (subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر المادة الدراسية أولًا.')),
      );
      return;
    }

    if ((isSummary || isQuestion) && lessonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر الدرس الذي يرتبط به هذا المحتوى.'),
        ),
      );
      return;
    }

    if (isQuestion) {
      if (optionControllers.any((controller) =>
          controller.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أكمل الخيارات الأربعة قبل الحفظ.'),
          ),
        );
        return;
      }
    }

    setState(() => saving = true);

    try {
      final user = db.auth.currentUser;

      final Map<String, dynamic> payload = {
        'subject_id': subjectId,
        'is_published': published,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (isLesson || isSummary) {
        payload['title'] = titleController.text.trim();
        payload['content'] = contentController.text.trim();
      }

      if (isSummary || isQuestion) {
        payload['lesson_id'] = lessonId;
      }

      if (isSummary || isQuestion) {
        payload['created_by'] = user?.id;
      }

      if (isQuestion) {
        payload['question_text'] = questionController.text.trim();
        payload['explanation'] = explanationController.text.trim();
        payload['question_type'] = 'multiple_choice';
        payload['points'] = 1;
      }

      dynamic savedItem;

      if (isEditing) {
        savedItem = await db
            .from(widget.type)
            .update(payload)
            .eq('id', widget.item!['id'])
            .select()
            .single();
      } else {
        payload['created_by'] = user?.id;
        savedItem = await db
            .from(widget.type)
            .insert(payload)
            .select()
            .single();
      }

      if (isQuestion) {
        final questionId = savedItem['id'].toString();

        if (isEditing) {
          await db
              .from('question_options')
              .delete()
              .eq('question_id', questionId);
        }

        final optionRows = <Map<String, dynamic>>[];

        for (int i = 0; i < 4; i++) {
          final key = const ['A', 'B', 'C', 'D'][i];

          optionRows.add({
            'question_id': questionId,
            'option_key': key,
            'option_text': optionControllers[i].text.trim(),
            'is_correct': key == correctOption,
            'display_order': i + 1,
          });
        }

        await db.from('question_options').insert(optionRows);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المحتوى بنجاح.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر حفظ المحتوى.\nتحقق من اتصال قاعدة البيانات وصلاحيات المدير.\n$e',
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'المادة الدراسية',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: widget.subjects.any(
                (subject) => subject['id'].toString() == subjectId,
              )
                  ? subjectId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: const Text('اختر المادة'),
              items: widget.subjects.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject['id'].toString(),
                  child: Text(subject['name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: isEditing
                  ? null
                  : (value) {
                      setState(() {
                        subjectId = value;
                        lessonId = null;
                      });

                      if (isSummary || isQuestion) loadLessons();
                    },
              validator: (value) =>
                  value == null ? 'اختر المادة' : null,
            ),
            const SizedBox(height: 18),
            if (isLesson || isSummary) ...[
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان المحتوى',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'أدخل العنوان'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contentController,
                minLines: 8,
                maxLines: 20,
                decoration: const InputDecoration(
                  labelText: 'النص التعليمي',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  hintText: 'اكتب محتوى الدرس أو الملخص هنا...',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'أدخل المحتوى'
                    : null,
              ),
            ],
            if (isSummary || isQuestion) ...[
              const SizedBox(height: 8),
              const Text(
                'الدرس المرتبط',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (lessonsLoading)
                const Center(child: CircularProgressIndicator())
              else if (lessons.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'لا توجد دروس لهذه المادة. أضف درسًا أولًا.',
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: lessons.any(
                    (lesson) => lesson['id'].toString() == lessonId,
                  )
                      ? lessonId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('اختر الدرس'),
                  items: lessons.map((lesson) {
                    return DropdownMenuItem<String>(
                      value: lesson['id'].toString(),
                      child: Text(
                        lesson['title']?.toString() ?? 'درس',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => lessonId = value),
                  validator: (value) =>
                      value == null ? 'اختر الدرس المرتبط' : null,
                ),
            ],
            if (isQuestion) ...[
              const SizedBox(height: 18),
              TextFormField(
                controller: questionController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'نص السؤال',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'أدخل نص السؤال'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'خيارات الإجابة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: optionControllers[i],
                    decoration: InputDecoration(
                      labelText:
                          'الخيار ${const ['A', 'B', 'C', 'D'][i]}',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'أدخل نص الخيار'
                            : null,
                  ),
                ),
              const Text(
                'حدد الإجابة الصحيحة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: correctOption,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('الخيار A')),
                  DropdownMenuItem(value: 'B', child: Text('الخيار B')),
                  DropdownMenuItem(value: 'C', child: Text('الخيار C')),
                  DropdownMenuItem(value: 'D', child: Text('الخيار D')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => correctOption = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: explanationController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'تفسير الإجابة (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SwitchListTile(
              value: published,
              onChanged: (value) => setState(() => published = value),
              title: const Text('نشر المحتوى للطلاب'),
              subtitle: const Text(
                'عند إيقافه سيبقى المحتوى مسودة داخل لوحة الإدارة.',
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saving ? null : saveContent,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ المحتوى'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخدمات')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'خدمات الطالب',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'يمكنك مراجعة المواد والدروس والملخصات والاختبارات من الصفحة الرئيسية.',
            style: TextStyle(height: 1.7),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.support_agent,
                color: Color(0xFFB54A55),
              ),
              title: const Text('طلب مساعدة'),
              subtitle: const Text('أرسل طلبًا إلى إدارة التطبيق'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceRequestPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.notifications_none,
                color: Color(0xFFB54A55),
              ),
              title: const Text('التنبيهات'),
              subtitle: const Text('عرض آخر التنبيهات المنشورة'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceRequestPage extends StatefulWidget {
  const ServiceRequestPage({super.key});

  @override
  State<ServiceRequestPage> createState() => _ServiceRequestPageState();
}

class _ServiceRequestPageState extends State<ServiceRequestPage> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  bool sending = false;

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    final user = db.auth.currentUser;

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل عنوان الطلب وتفاصيله.')),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجّل الدخول أولًا لإرسال الطلب.')),
      );
      return;
    }

    setState(() => sending = true);

    try {
      await db.from('admin_requests').insert({
        'user_id': user.id,
        'title': title,
        'content': body,
        'status': 'pending',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلبك إلى الإدارة.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إرسال الطلب. قد تختلف أعمدة جدول الطلبات في قاعدة بياناتك.\n$e',
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلب مساعدة')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'اكتب طلبك بوضوح، وستتمكن الإدارة من مراجعته.',
            style: TextStyle(height: 1.7),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الطلب',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: bodyController,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'تفاصيل الطلب',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: sending ? null : sendRequest,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Text(sending ? 'جارٍ الإرسال...' : 'إرسال الطلب'),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final result = await db
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (!mounted) return;

      setState(() {
        notifications = List<Map<String, dynamic>>.from(result);
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? ErrorView(message: error, onRetry: loadNotifications)
              : notifications.isEmpty
                  ? const Center(
                      child: Text('لا توجد تنبيهات حتى الآن.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFFB54A55),
                            ),
                            title: Text(
                              item['title']?.toString() ?? 'تنبيه',
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                item['content']?.toString() ??
                                    item['message']?.toString() ??
                                    '',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> signOut(BuildContext context) async {
    try {
      await db.auth.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الخروج: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = db.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFB54A55).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 48,
                  color: Color(0xFFB54A55),
                ),
                const SizedBox(height: 10),
                const Text(
                  'حسابك',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(user?.email ?? 'حساب الطالب'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('دخول المدير'),
              subtitle: const Text('إدارة الدروس والملخصات والأسئلة'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPage(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('حول التطبيق'),
              subtitle: const Text('البريهي التعليمي'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'البريهي التعليمي',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'مع تحياتي برهان البريهي',
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => signOut(context),
            icon: const Icon(Icons.logout),
            label: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('تسجيل الخروج'),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'مع تحياتي برهان البريهي',
              style: TextStyle(
                color: Color(0xFFD4A04D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 52,
            ),
            const SizedBox(height: 14),
            const Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              message,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}