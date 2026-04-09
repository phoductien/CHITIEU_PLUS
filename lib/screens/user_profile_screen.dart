import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/transaction_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedDob = '';
  String _selectedGender = 'Nam';

  final List<String> _predefinedAvatars = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Luna',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Max',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Coco',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Milo',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Leo',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Bella',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Charlie',
  ];

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.name);
    _emailController = TextEditingController(text: userProvider.email);
    _phoneController = TextEditingController(text: userProvider.phone);
    _selectedDob = userProvider.dob.isNotEmpty
        ? userProvider.dob
        : '01/01/2000';
    _selectedGender = userProvider.gender.isNotEmpty
        ? userProvider.gender
        : 'Nam';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 60,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);

        if (!mounted) return;
        final userProvider = context.read<UserProvider>();
        await userProvider.setPhotoUrl('data:image/jpeg;base64,$base64String');
        // We do sync later on Save, but for avatar we can sync immediately so it updates everywhere.
        await userProvider.syncToFirebase();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật ảnh đại diện thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: \$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPredefinedAvatarsBottomSheet(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Chọn từ bộ sưu tập',
                  style: TextStyle(
                    color: themeProvider.foregroundColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _predefinedAvatars.length,
                  itemBuilder: (context, index) {
                    final url = _predefinedAvatars[index];
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        Navigator.pop(context);

                        setState(() => _isLoading = true);
                        if (!context.mounted) return;
                        final userProvider = context.read<UserProvider>();
                        await userProvider.setPhotoUrl(url);
                        await userProvider.syncToFirebase();

                        if (context.mounted) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cập nhật ảnh đại diện thành công!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFFFD180),
                        backgroundImage: NetworkImage(url),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showAvatarOptionsBottomSheet() {
    final themeProvider = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeProvider.foregroundColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: themeProvider.foregroundColor,
                ),
                title: Text(
                  'Chọn ảnh từ thư viện',
                  style: TextStyle(color: themeProvider.foregroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: themeProvider.foregroundColor,
                ),
                title: Text(
                  'Chụp ảnh mới',
                  style: TextStyle(color: themeProvider.foregroundColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.face_retouching_natural_rounded,
                  color: themeProvider.foregroundColor,
                ),
                title: Text(
                  'Chọn từ bộ sưu tập',
                  style: TextStyle(color: themeProvider.foregroundColor),
                ),
                onTap: () {
                  _showPredefinedAvatarsBottomSheet(themeProvider);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  ImageProvider _getAvatarImage(String photoUrl) {
    if (photoUrl.isEmpty) {
      return const NetworkImage(
        'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
      );
    }
    if (photoUrl.startsWith('data:image/')) {
      final base64Str = photoUrl.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    }
    return NetworkImage(photoUrl);
  }

  Future<void> _selectDate() async {
    final themeProvider = context.read<ThemeProvider>();
    final initialDate =
        DateTime.tryParse(_selectedDob.split('/').reversed.join('-')) ??
        DateTime(2000, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: themeProvider.isDarkMode
                ? const ColorScheme.dark(primary: Colors.blue)
                : const ColorScheme.light(primary: Colors.blue),
            dialogTheme: DialogThemeData(
              backgroundColor: themeProvider.backgroundColor,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob =
            "\${picked.day.toString().padLeft(2, '0')}/\${picked.month.toString().padLeft(2, '0')}/\${picked.year}";
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();

    await userProvider.setName(_nameController.text.trim());
    await userProvider.setEmail(_emailController.text.trim());
    await userProvider.setPhone(_phoneController.text.trim());
    await userProvider.setDob(_selectedDob);
    await userProvider.setGender(_selectedGender);

    await userProvider.syncToFirebase();

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Thông tin tài khoản',
          style: TextStyle(
            color: themeProvider.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: themeProvider.backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: themeProvider.foregroundColor),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeProvider.foregroundColor,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Blue gradient Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _showAvatarOptionsBottomSheet,
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Colors.blue.shade200,
                                    child: CircleAvatar(
                                      radius: 52,
                                      backgroundColor: const Color(0xFFFFD180),
                                      backgroundImage: _getAvatarImage(
                                        userProvider.photoUrl,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showAvatarOptionsBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userProvider.name.isNotEmpty
                                ? userProvider.name
                                : 'Khách',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (userProvider.isGuest || userProvider.name.isEmpty)
                                ? 'Tài khoản Khách'
                                : 'Thành viên Bạc',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Form Fields
                    _buildTextField(
                      theme: themeProvider,
                      icon: Icons.person_rounded,
                      label: 'Họ và tên',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      theme: themeProvider,
                      icon: Icons.email_rounded,
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      theme: themeProvider,
                      icon: Icons.phone_rounded,
                      label: 'Số điện thoại',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth & Gender Row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: _buildStaticField(
                              theme: themeProvider,
                              icon: Icons.calendar_today_rounded,
                              label: 'Ngày sinh',
                              value: _selectedDob,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            theme: themeProvider,
                            icon: Icons.people_alt_rounded,
                            label: 'Giới tính',
                            value: _selectedGender,
                            items: ['Nam', 'Nữ', 'Khác'],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGender = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC5B13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Data Management Section
                    const Divider(),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quản lý dữ liệu',
                        style: TextStyle(
                          color: themeProvider.foregroundColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nếu dữ liệu bị sai lệch hoặc không hiển thị đúng so với Cloud, hãy nhấn nút bên dưới để dọn dẹp và đồng bộ lại.',
                      style: TextStyle(
                        color: themeProvider.foregroundColor.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          try {
                            await context
                                .read<TransactionProvider>()
                                .syncDataWithFirestore();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đồng bộ dữ liệu thành công!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi đồng bộ: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text(
                          'Đồng bộ lại từ Cloud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.foregroundColor.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(
                icon,
                color: theme.foregroundColor.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    color: theme.foregroundColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticField({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.foregroundColor.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                icon,
                color: theme.foregroundColor.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: theme.foregroundColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.secondaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.foregroundColor.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(
                icon,
                color: theme.foregroundColor.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.foregroundColor.withValues(alpha: 0.5),
                    ),
                    dropdownColor: theme.secondaryColor,
                    style: TextStyle(
                      color: theme.foregroundColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: onChanged,
                    items: items.map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(val),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // slightly balance padding
        ],
      ),
    );
  }
}
