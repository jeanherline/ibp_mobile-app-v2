import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'form_state_provider.dart';
import 'barangay_certificate_of_indigency.dart';
import 'progress_bar.dart'; // Import the custom progress bar widget

class NatureOfLegalAssistanceRequested extends StatefulWidget {
  const NatureOfLegalAssistanceRequested({super.key});

  @override
  _NatureOfLegalAssistanceRequestedState createState() =>
      _NatureOfLegalAssistanceRequestedState();
}

class _NatureOfLegalAssistanceRequestedState
    extends State<NatureOfLegalAssistanceRequested> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAssistanceType;
  final TextEditingController _problemsController = TextEditingController();
  final TextEditingController _problemReasonController =
      TextEditingController();
  final TextEditingController _desiredSolutionsController =
      TextEditingController();

  final List<String> assistanceOptions = [
    'Payong Legal (Legal Advice)',
    'Legal na Representasyon (Legal Representation)',
    'Pag gawa ng Legal na Dokumento (Drafting of Legal Document)'
  ];

  @override
  void initState() {
    super.initState();
    final formState = context.read<FormStateProvider>();
    _selectedAssistanceType = formState.selectedAssistanceType.isNotEmpty &&
            assistanceOptions.contains(formState.selectedAssistanceType)
        ? formState.selectedAssistanceType
        : null;
    _problemsController.text = formState.problems;
    _problemReasonController.text = formState.problemReason;
    _desiredSolutionsController.text = formState.desiredSolutions;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
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
                    child: CustomProgressBar(currentStep: 2, totalSteps: 6),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Nature of Legal Assistance Requested',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdownField(
                    'Klase ng tulong legal',
                    'Nature of Legal assistance',
                    assistanceOptions,
                    _selectedAssistanceType,
                    'Piliin ang klase ng tulong legal (Choose nature of legal assistance)',
                    true,
                    (value) {
                      setState(() {
                        _selectedAssistanceType = value;
                      });
                    },
                    screenWidth,
                  ),
                  const SizedBox(height: 20),
                  _buildTextAreaField(
                    'Ano ang iyong problema?',
                    'Enter your problem/s or complaint/s',
                    _problemsController,
                    'Ilagay ang iyong problema (Enter your problem/s or complaint/s)',
                    true,
                    screenWidth,
                  ),
                  const SizedBox(height: 20),
                  _buildTextAreaField(
                    'Bakit o papaano nagkaroon ng ganoong problema?',
                    'Why or how did such problem/s arise?',
                    _problemReasonController,
                    'Ilagay ang dahilan ng problema (Enter the reason why or how the problem/s arise)',
                    true,
                    screenWidth,
                  ),
                  const SizedBox(height: 20),
                  _buildTextAreaField(
                    'Ano ang mga maaaring solusyon na gusto mong ibigay ng Abogado sa iyo?',
                    'What possible solution/s would you like to be given by the lawyer to you?',
                    _desiredSolutionsController,
                    'Ilagay ang mga maaaring solusyon (Enter the possible solution/s would you like)',
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
                          // Save form state
                          final formState = context.read<FormStateProvider>();
                          formState.updateNatureOfLegalAssistanceRequested(
                            selectedAssistanceType:
                                _selectedAssistanceType ?? '',
                            problems: _problemsController.text,
                            problemReason: _problemReasonController.text,
                            desiredSolutions: _desiredSolutionsController.text,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BarangayCertificateOfIndigency(),
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

  Widget _buildDropdownField(
    String label,
    String subLabel,
    List<String> items,
    String? selectedItem,
    String hintText,
    bool isRequired,
    ValueChanged<String?> onChanged,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: '$label ',
            style:
                TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
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
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 18.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                value: selectedItem,
                onChanged: onChanged,
                validator: isRequired
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field cannot be empty';
                        }
                        return null;
                      }
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTextAreaField(
    String label,
    String subLabel,
    TextEditingController controller,
    String hintText,
    bool isRequired,
    double screenWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: '$label ',
            style:
                TextStyle(color: Colors.black, fontSize: screenWidth * 0.045),
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
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
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
}
