import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedGender = '';
  String _selectedDenomination = '';
  String _selectedExperience = '';
  List<String> _selectedInterests = [];

  final List<String> _genders = [
    'Homme',
    'Femme',
    'Préfère ne pas dire',
  ];

  final List<String> _denominations = [
    'Catholique',
    'Protestant',
    'Évangélique',
    'Orthodoxe',
    'Autre',
    'Non affilié',
  ];

  final List<String> _experienceLevels = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Érudit',
  ];

  final List<String> _interests = [
    'Étude biblique',
    'Prière',
    'Méditation',
    'Évangélisation',
    'Service communautaire',
    'Musique chrétienne',
    'Histoire biblique',
    'Théologie',
    'Apologétique',
    'Ministère',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Compléter le Profil',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Sauvegarder',
              style: GoogleFonts.inter(
                color: const Color(0xFF8B7355),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B7355).withOpacity(0.1),
                      const Color(0xFF8B7355).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8B7355).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 48,
                      color: const Color(0xFF8B7355),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Complétez votre profil',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ces informations nous aideront à personnaliser votre expérience',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Personal Information Section
              _buildSection(
                'Informations personnelles',
                Icons.person_rounded,
                [
                  _buildNameFields(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildAgeField(),
                  const SizedBox(height: 16),
                  _buildLocationField(),
                  const SizedBox(height: 16),
                  _buildGenderDropdown(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Spiritual Information Section
              _buildSection(
                'Informations spirituelles',
                Icons.church_rounded,
                [
                  _buildDenominationDropdown(),
                  const SizedBox(height: 16),
                  _buildExperienceDropdown(),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Interests Section
              _buildSection(
                'Centres d\'intérêt',
                Icons.favorite_rounded,
                [
                  _buildInterestsSelector(),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B7355),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Compléter le Profil',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B7355).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF8B7355),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            'Prénom',
            _firstNameController,
            Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir votre prénom';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTextField(
            'Nom',
            _lastNameController,
            Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir votre nom';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildTextField(
      'Email',
      _emailController,
      Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez saisir votre email';
        }
        if (!value.contains('@')) {
          return 'Veuillez saisir un email valide';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return _buildTextField(
      'Âge',
      _ageController,
      Icons.cake_outlined,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez saisir votre âge';
        }
        final age = int.tryParse(value);
        if (age == null || age < 1 || age > 120) {
          return 'Veuillez saisir un âge valide';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return _buildTextField(
      'Ville/Pays',
      _locationController,
      Icons.location_on_outlined,
    );
  }

  Widget _buildGenderDropdown() {
    return _buildDropdown(
      'Genre',
      _selectedGender,
      _genders,
      (value) => setState(() => _selectedGender = value!),
    );
  }

  Widget _buildDenominationDropdown() {
    return _buildDropdown(
      'Dénomination',
      _selectedDenomination,
      _denominations,
      (value) => setState(() => _selectedDenomination = value!),
    );
  }

  Widget _buildExperienceDropdown() {
    return _buildDropdown(
      'Niveau d\'expérience biblique',
      _selectedExperience,
      _experienceLevels,
      (value) => setState(() => _selectedExperience = value!),
    );
  }

  Widget _buildInterestsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Centres d\'intérêt (sélectionnez plusieurs)',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interests.map((interest) {
            final isSelected = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () => _toggleInterest(interest),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF8B7355) 
                      : const Color(0xFF3A3A3C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF8B7355) 
                        : const Color(0xFF5A5A5C),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Entrez $label',
            hintStyle: GoogleFonts.inter(color: Colors.white54),
            prefixIcon: Icon(icon, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF3A3A3C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              isExpanded: true,
              dropdownColor: const Color(0xFF3A3A3C),
              style: GoogleFonts.inter(color: Colors.white),
              hint: Text(
                'Sélectionnez $label',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Save profile data (simulation)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil complété avec succès !'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      
      // Navigate to home
      context.pushReplacement('/home');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}