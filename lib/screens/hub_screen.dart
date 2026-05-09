import 'package:flutter/material.dart';
import 'package:o_web/theme.dart';
import 'package:o_web/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  bool _isAdmin = false;
  List<HubPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.getMyProfile();
      final posts = await SupabaseService.getHubPosts();
      if (mounted) {
        setState(() {
          _isAdmin = profile?.isAdmin ?? false;
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreatePostDialog([HubPost? post]) {
    showDialog(
      context: context,
      builder: (context) => _CreatePostDialog(onSuccess: _loadData, post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: OTheme.neonPink));
    }

    final featuredPosts = _posts.where((p) => p.type == HubPostType.featured).toList();
    final updatePosts = _posts.where((p) => p.type == HubPostType.update).toList();
    final comingSoonPosts = _posts.where((p) => p.type == HubPostType.comingSoon).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCreatePostDialog,
              backgroundColor: OTheme.neonPink,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: OTheme.neonPink,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Afternoon, Explorer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Stay updated with the latest from O.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (_isAdmin && _posts.isEmpty)
                    TextButton.icon(
                      onPressed: _seedDummyData,
                      icon: const Icon(Icons.auto_fix_high, color: OTheme.neonPink),
                      label: const Text('Seed Initial Content', style: TextStyle(color: OTheme.neonPink)),
                    ),
                ],
              ),
              const SizedBox(height: 48),
              
              if (featuredPosts.isNotEmpty) ...[
                const _SectionHeader(title: 'Featured News'),
                const SizedBox(height: 24),
                ...featuredPosts.map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _FeaturedCard(
                    title: post.title,
                    subtitle: post.subtitle ?? '',
                    image: post.imageUrl ?? 'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?auto=format&fit=crop&q=80&w=1000',
                    tag: post.tag,
                    onEdit: _isAdmin ? () => _showCreatePostDialog(post) : null,
                  ),
                )),
                const SizedBox(height: 24),
              ],
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'Latest Updates'),
                        const SizedBox(height: 24),
                        if (updatePosts.isEmpty)
                          const Text('No updates yet.', style: TextStyle(color: Colors.white38))
                        else
                          ...updatePosts.map((post) => _UpdateItem(
                            title: post.title,
                            date: DateFormat('MMM dd, yyyy').format(post.createdAt),
                            description: post.subtitle ?? '',
                            icon: _getIconForTag(post.tag),
                            imageUrl: post.imageUrl,
                            onEdit: _isAdmin ? () => _showCreatePostDialog(post) : null,
                          )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(title: 'Coming Soon'),
                        const SizedBox(height: 24),
                        if (comingSoonPosts.isEmpty)
                          const Text('Nothing planned yet.', style: TextStyle(color: Colors.white38))
                        else
                          ...comingSoonPosts.map((post) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _ComingSoonCard(
                              title: post.title,
                              description: post.subtitle ?? '',
                              icon: _getIconForTag(post.tag),
                              imageUrl: post.imageUrl,
                              onEdit: _isAdmin ? () => _showCreatePostDialog(post) : null,
                            ),
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTag(String tag) {
    switch (tag.toUpperCase()) {
      case 'SECURITY': return Icons.security_outlined;
      case 'ALGORITHM': return Icons.auto_awesome_outlined;
      case 'COMMUNITY': return Icons.groups_outlined;
      case 'PREMIUM': return Icons.star_border_purple500_outlined;
      case 'EVENT': return Icons.event_outlined;
      default: return Icons.info_outline;
    }
  }

  Future<void> _seedDummyData() async {
    setState(() => _isLoading = true);
    final dummyPosts = [
      HubPost(
        id: '',
        title: 'Welcome to the New O Web',
        subtitle: 'Experience the full power of O on your desktop. Faster, sleeker, and more intuitive.',
        imageUrl: 'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?auto=format&fit=crop&q=80&w=1000',
        tag: 'NEW FEATURE',
        type: HubPostType.featured,
        createdAt: DateTime.now(),
      ),
      HubPost(
        id: '',
        title: 'Enhanced Privacy Controls',
        subtitle: 'We\'ve added more granular controls over who can see your profile details.',
        tag: 'SECURITY',
        type: HubPostType.update,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      HubPost(
        id: '',
        title: 'O Premium',
        subtitle: 'Unlock exclusive features and priority matching.',
        tag: 'PREMIUM',
        type: HubPostType.comingSoon,
        createdAt: DateTime.now(),
      ),
    ];

    for (var post in dummyPosts) {
      await SupabaseService.createHubPost(post);
    }
    _loadData();
  }
}

class _CreatePostDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final HubPost? post;
  const _CreatePostDialog({required this.onSuccess, this.post});

  @override
  State<_CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<_CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _tagController;
  late HubPostType _type;
  bool _isSaving = false;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isCropping = false;
  final _cropController = CropController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title);
    _subtitleController = TextEditingController(text: widget.post?.subtitle);
    _imageUrlController = TextEditingController(text: widget.post?.imageUrl);
    _tagController = TextEditingController(text: widget.post?.tag ?? 'UPDATE');
    _type = widget.post?.type ?? HubPostType.update;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _selectedFileBytes = result.files.first.bytes;
        _selectedFileName = result.files.first.name;
        _isCropping = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: OTheme.deepCharcoal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        height: _isCropping ? 700 : null,
        padding: const EdgeInsets.all(32),
        child: _isCropping ? _buildCropper() : _buildForm(),
      ),
    );
  }

  Widget _buildCropper() {
    return Column(
      children: [
        const Text(
          'Adjust Image Visibility',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the area you want to be visible in the post.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Crop(
              image: _selectedFileBytes!,
              controller: _cropController,
              onCropped: (image) {
                setState(() {
                  _selectedFileBytes = image;
                  _isCropping = false;
                  _imageUrlController.text = 'Cropped & Ready';
                });
              },
              aspectRatio: _type == HubPostType.featured ? 16 / 9 : 4 / 3,
              initialSize: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _isCropping = false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _cropController.crop(),
              icon: const Icon(Icons.check),
              label: const Text('Apply Crop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: OTheme.neonPink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post == null ? 'Create New Hub Post' : 'Edit Hub Post',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
                DropdownButtonFormField<HubPostType>(
                  value: _type,
                  dropdownColor: OTheme.deepCharcoal,
                  decoration: const InputDecoration(labelText: 'Post Type'),
                  items: HubPostType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  )).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtitleController,
                  decoration: const InputDecoration(labelText: 'Subtitle / Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tagController,
                  decoration: const InputDecoration(labelText: 'Tag (e.g. SECURITY, EVENT)'),
                ),
                const SizedBox(height: 24),
                const Text('Media Content', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'Paste a URL or upload from device',
                        ),
                        readOnly: _selectedFileBytes != null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OTheme.deepCharcoal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
                if (_selectedFileBytes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(_selectedFileBytes!),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: OTheme.neonPink.withOpacity(0.3)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: OTheme.neonPink, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Image Cropped: $_selectedFileName',
                        style: const TextStyle(color: OTheme.neonPink, fontSize: 12),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text('Change', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.post == null ? 'Post to Hub' : 'Update Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    try {
      String? imageUrl = _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null;
      
      // Handle file upload if a new file was selected
      if (_selectedFileBytes != null && _selectedFileName != null) {
        imageUrl = await SupabaseService.uploadHubMedia(_selectedFileBytes!, _selectedFileName!);
      }

      if (widget.post != null) {
        final updatedPost = widget.post!.copyWith(
          title: _titleController.text,
          subtitle: _subtitleController.text,
          imageUrl: imageUrl,
          tag: _tagController.text,
          type: _type,
        );
        await SupabaseService.updateHubPost(updatedPost);
      } else {
        final post = HubPost(
          id: '',
          title: _titleController.text,
          subtitle: _subtitleController.text,
          imageUrl: imageUrl,
          tag: _tagController.text,
          type: _type,
          createdAt: DateTime.now(),
        );
        await SupabaseService.createHubPost(post);
      }
      
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: OTheme.neonPink,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final String tag;
  final VoidCallback? onEdit;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.tag,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: OTheme.neonPink,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  const SizedBox(height: 12, child: VerticalDivider(color: Colors.white24, width: 1)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onEdit,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'EDIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 500,
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateItem extends StatelessWidget {
  final String title;
  final String date;
  final String description;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback? onEdit;

  const _UpdateItem({
    required this.title,
    required this.date,
    required this.description,
    required this.icon,
    this.imageUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OTheme.deepCharcoal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: OTheme.neonPink, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 14,
                      ),
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, color: OTheme.neonPink, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback? onEdit;

  const _ComingSoonCard({
    required this.title,
    required this.description,
    required this.icon,
    this.imageUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: OTheme.deepCharcoal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white54, size: 32),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
