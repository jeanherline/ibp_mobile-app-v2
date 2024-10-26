import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'form_state_provider.dart';
import 'nature_of_legal_assitance_requested.dart';
import 'progress_bar.dart';

class EmploymentProfile extends StatefulWidget {
  const EmploymentProfile({super.key});

  @override
  _EmploymentProfileState createState() => _EmploymentProfileState();
}

class _EmploymentProfileState extends State<EmploymentProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _employerNameController = TextEditingController();
  final TextEditingController _employerAddressController =
      TextEditingController();
  final TextEditingController _monthlyIncomeController =
      TextEditingController();

  final List<String> employmentOptions = [
    'Lokal na Trabaho (Local Employer/Agency)',
    'Dayuhang Amo (Foreign Employer)',
    'Sa sarili nagtatrabaho (Self-Employed)',
    'Iba pa (Others)'
  ];

  String? _selectedEmploymentOption;

  @override
  void initState() {
    super.initState();
    final formState = context.read<FormStateProvider>();
    _occupationController.text = formState.occupation;
    _employerNameController.text = formState.employerName;
    _employerAddressController.text = formState.employerAddress;
    _monthlyIncomeController.text = formState.monthlyIncome;
    _selectedEmploymentOption = formState.kindOfEmployment.isNotEmpty &&
            employmentOptions.contains(formState.kindOfEmployment)
        ? formState.kindOfEmployment
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            _saveTextValues();
            Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Isumite ang Suliraning Legal',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '(Submit your legal problem)',
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Center(
                    child: CustomProgressBar(currentStep: 1, totalSteps: 6),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Impormasyon patungkol sa Trabaho',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '(Employment Profile, if any)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Hanapbuhay',
                    'Occupation',
                    _occupationController,
                    'Ilagay ang hanapbuhay (Enter occupation)',
                    true,
                    screenWidth,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    'Klase ng Trabaho',
                    'Kind of Employment',
                    _selectedEmploymentOption,
                    employmentOptions,
                    'Piliin ang klase ng trabaho (Choose kind of employment)',
                    true,
                    (String? newValue) {
                      setState(() {
                        _selectedEmploymentOption = newValue;
                      });
                    },
                    screenWidth,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Pangalan ng iyong Amo',
                    'Employer’s Name',
                    _employerNameController,
                    'Ilagay ang pangalan ng amo (Enter employer’s name)',
                    false,
                    screenWidth,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    'Adres o Tinitirahan ng amo',
                    'Employer’s Address',
                    _employerAddressController,
                    'Ilagay ang adres o tinitirahan ng amo (Enter employer’s address)',
                    false,
                    screenWidth,
                  ),
                  const SizedBox(height: 20),
                  _buildNumberField(
                    'Buwanang sahod ng buong pamilya',
                    'Monthly Family Income',
                    _monthlyIncomeController,
                    'Ilagay ang buwanang sahod ng buong pamilya (Enter family’s monthly income)',
                    true,
                    screenWidth,
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: const Color(0xFF580049),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _saveTextValues();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NatureOfLegalAssistanceRequested(),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: 'Sunod ',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.white,
                              ),
                              children: const <TextSpan>[
                                TextSpan(
                                  text: '(Next)',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveTextValues() {
    final formState = context.read<FormStateProvider>();
    formState.updateEmploymentProfile(
      occupation: _occupationController.text,
      kindOfEmployment: _selectedEmploymentOption ?? '',
      employerName: _employerNameController.text,
      employerAddress: _employerAddressController.text,
      monthlyIncome: _monthlyIncomeController.text,
    );
  }

  Widget _buildTextField(
      String label,
      String subLabel,
      TextEditingController controller,
      String hintText,
      bool isRequired,
      double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildNumberField(
      String label,
      String subLabel,
      TextEditingController controller,
      String hintText,
      bool isRequired,
      double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String subLabel,
    String? selectedItem,
    List<String> items,
    String hintText,
    bool isRequired,
    ValueChanged<String?> onChanged,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, subLabel, isRequired, screenWidth),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedItem,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          isExpanded: true, // Ensures the dropdown expands to the full width
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field cannot be empty';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildLabel(
      String label, String subLabel, bool isRequired, double screenWidth) {
    return RichText(
      text: TextSpan(
        text: '$label ',
        style: TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
        children: [
          TextSpan(
            text: '($subLabel)',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: screenWidth * 0.04,
            ),
          ),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
