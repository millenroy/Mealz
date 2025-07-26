import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../api/api_service.dart';
import '../../models/delivery_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../login_screen.dart';

class ManageMealPlanScreen extends StatefulWidget {
  const ManageMealPlanScreen({super.key});

  @override
  State<ManageMealPlanScreen> createState() => _ManageMealPlanScreenState();
}

class _ManageMealPlanScreenState extends State<ManageMealPlanScreen> {
  final ApiService _apiService = ApiService(UserProvider());
  late Future<Map<String, dynamic>> _pageData;
  DateTime _selectedDate = DateTime.now();
  DateTime _subscriptionValidUntil = DateTime.now().add(
    const Duration(days: 60),
  );
  final ScrollController _dateScrollController = ScrollController();

  String? selectedAddress;
  String? selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _pageData = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) throw Exception('No user selected');
      final deliveries = await _apiService.getDeliveries(_selectedDate, userId);
      final user = await _apiService.getUserDetails(userId);
      final timeSlots = await _apiService.getTimeSlots();

      _subscriptionValidUntil = user.subscriptionValidUntil;

      return {'deliveries': deliveries, 'user': user, 'timeSlots': timeSlots};
    } catch (e) {
      throw Exception("Could not load page data. Error: $e");
    }
  }

  void _reloadData() {
    setState(() {
      _pageData = _loadData();
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _reloadData();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelectedDate(),
    );
  }

  void _scrollToSelectedDate() {
    final startDate = DateTime.now();
    final index = _selectedDate.difference(startDate).inDays;
    if (index >= 0 && _dateScrollController.hasClients) {
      _dateScrollController.animateTo(
        index * 76.0, // 68 width + 8 margin
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _pageData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available.'));
          }

          final Map<String, dynamic> data = snapshot.data!;
          final List<Delivery> deliveries = data['deliveries'];
          final User user = data['user'];
          final List<String> timeSlots = data['timeSlots'];

          final filteredDeliveries = deliveries.where((d) {
            final addressMatch =
                selectedAddress == null || d.address == selectedAddress;
            final timeSlotMatch =
                selectedTimeSlot == null || d.timeSlot == selectedTimeSlot;
            return addressMatch && timeSlotMatch;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'Your meal plan',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildDateSelector(),
              _buildFilterRow(user, timeSlots),
              Expanded(
                child: filteredDeliveries.isEmpty
                    ? const Center(
                        child: Text('No deliveries scheduled for this day.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: filteredDeliveries.length,
                        itemBuilder: (context, index) {
                          return _buildDeliveryCard(
                            filteredDeliveries[index],
                            user,
                            timeSlots,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    final startDate = DateTime.now();
    final endDate = _subscriptionValidUntil;
    final totalDays = endDate.difference(startDate).inDays + 1;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final date = startDate.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 68,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(User user, List<String> timeSlots) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedAddress,
              decoration: _buildDropdownDecoration('Filter by Address'),
              items: user.addresses
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.nickname,
                      child: Text(a.nickname),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedAddress = val),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedTimeSlot,
              decoration: _buildDropdownDecoration('Filter by Time'),
              items: timeSlots
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => selectedTimeSlot = val),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildDropdownDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      floatingLabelStyle: const TextStyle(color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  Widget _buildDeliveryCard(
    Delivery delivery,
    User user,
    List<String> timeSlots,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery for ${DateFormat.MMMEd().format(delivery.deliveryDate)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showRescheduleDialog(delivery, timeSlots),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Reschedule'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Time Slot: ${delivery.timeSlot}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Divider(height: 24),

              // Pickup/Delivery Toggle
              SwitchListTile(
                title: const Text(
                  'Change to Pickup',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                value: delivery.deliveryType == 'pickup',
                onChanged: (val) async {
                  await _apiService.updateDeliverySlot(
                    delivery.id,
                    isPickup: val,
                  );
                  _reloadData();
                },
                activeColor: const Color.fromARGB(255, 0, 218, 131),
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(height: 24),

              // Meal Items
              ...delivery.items.map(
                (item) => _buildMealItem(delivery.id, item),
              ),

              // Consolidated Action Buttons
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      'Skip Delivery',
                      Icons.fast_forward,
                      () async {
                        for (final item in delivery.items) {
                          try {
                            await _apiService.skipItem(delivery.id, item.id);
                          } catch (e) {
                            // print('Failed to skip item ${item.id}: $e');
                          }
                        }
                        _reloadData();
                      },
                    ),
                    _buildActionButton(
                      'Move Delivery',
                      Icons.arrow_forward,
                      () async {
                        final nextDay = delivery.deliveryDate.add(
                          const Duration(days: 1),
                        );
                        if (nextDay.isBefore(_subscriptionValidUntil)) {
                          await _apiService.moveMeal(
                            delivery.id,
                            DateTime.utc(
                              nextDay.year,
                              nextDay.month,
                              nextDay.day,
                            ),
                          );
                          _reloadData();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealItem(String deliveryId, DeliveryItem item) {
    bool isSkipped = item.status == 'skipped';
    return Opacity(
      opacity: isSkipped ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          onTap: isSkipped ? null : () => _showSwapDialog(deliveryId, item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSkipped ? Colors.grey.shade100 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.meal.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        // Image is fully loaded, show the image itself
                        return child;
                      }

                      // Calculate progress if available, otherwise null for indeterminate
                      final double? progress =
                          loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null;

                      return Container(
                        width: 60,
                        height: 60,
                        color:
                            Colors.grey[200], // bgcolor loading
                        child: Center(
                          child: progress == null || progress < 0.1
                              ? // Show a small CircularProgressIndicator initially
                                SizedBox(
                                  width: 24, // Adjust size of loader
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth:
                                        2, // Thinner stroke for small loader
                                    value:
                                        progress, // Show actual progress if known
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ), // Customize color
                                  ),
                                )
                              : // Once some progress is made, or after a very brief initial loader, show the asset placeholder
                                Image.asset(
                                  'assets/images/placeholder_meal.jpg', // Your placeholder image
                                  width: 40, // Adjust size as needed
                                  height: 40, // Adjust size as needed
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                      ), // Fallback for placeholder itself
                                ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.meal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.meal.description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (isSkipped)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            'SKIPPED',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isSkipped)
                  const Icon(Icons.swap_horiz, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 18,
        color: onPressed == null ? Colors.grey : Colors.black,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: onPressed == null ? Colors.grey : Colors.black,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showRescheduleDialog(
    Delivery delivery,
    List<String> timeSlots,
  ) async {
    DateTime newDate = delivery.deliveryDate;
    String newTimeSlot = delivery.timeSlot;

    TimeOfDay _parseTime(String time) {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    // This function now returns the corrected values.
    Map<String, dynamic> validateAndCorrectSelection(
      DateTime date,
      String timeSlot,
    ) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime correctedDate = date;
      String correctedTimeSlot = timeSlot;

      if (correctedDate.isBefore(today)) {
        correctedDate = today;
      }

      final isToday = DateUtils.isSameDay(correctedDate, today);

      if (isToday) {
        final timeNow = TimeOfDay.fromDateTime(now);
        final selectedSlotTime = _parseTime(correctedTimeSlot);

        bool isPast =
            selectedSlotTime.hour < timeNow.hour ||
            (selectedSlotTime.hour == timeNow.hour &&
                selectedSlotTime.minute <= timeNow.minute);

        if (isPast) {
          String? nextAvailableSlot;
          for (final slot in timeSlots) {
            final slotTime = _parseTime(slot);
            if (slotTime.hour > timeNow.hour ||
                (slotTime.hour == timeNow.hour &&
                    slotTime.minute > timeNow.minute)) {
              nextAvailableSlot = slot;
              break;
            }
          }

          if (nextAvailableSlot != null) {
            correctedTimeSlot = nextAvailableSlot;
          } else {
            correctedDate = correctedDate.add(const Duration(days: 1));
            correctedTimeSlot = timeSlots.first;
          }
        }
      }
      return {'date': correctedDate, 'timeSlot': correctedTimeSlot};
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Run validation on initial build
            final initialValidation = validateAndCorrectSelection(
              newDate,
              newTimeSlot,
            );
            newDate = initialValidation['date'];
            newTimeSlot = initialValidation['timeSlot'];

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Reschedule Delivery',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Date: ${DateFormat.yMMMd().format(newDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: newDate,
                        firstDate: DateTime.now(),
                        lastDate: _subscriptionValidUntil,
                      );
                      if (picked != null) {
                        // Re-validate after picking a new date
                        final validationResult = validateAndCorrectSelection(
                          picked,
                          newTimeSlot,
                        );
                        setStateDialog(() {
                          newDate = validationResult['date'];
                          newTimeSlot = validationResult['timeSlot'];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: newTimeSlot,
                    items: timeSlots
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        // Re-validate after manually changing the time
                        final validationResult = validateAndCorrectSelection(
                          newDate,
                          val,
                        );
                        setStateDialog(() {
                          newDate = validationResult['date'];
                          newTimeSlot = validationResult['timeSlot'];
                        });
                      }
                    },
                    decoration: _buildDropdownDecoration('Time Slot'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _apiService.rescheduleDeliverySlot(
                      delivery.id,
                      DateTime.utc(newDate.year, newDate.month, newDate.day),
                      newTimeSlot,
                    );
                    Navigator.pop(context);
                    _reloadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSwapDialog(String deliveryId, DeliveryItem item) async {
    final meals = await _apiService.getMeals();
    String? selectedMealId;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Swap Meal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: DropdownButtonFormField<String>(
                value: selectedMealId,
                items: meals
                    .map(
                      (meal) => DropdownMenuItem(
                        value: meal.id,
                        child: SizedBox(
                          width:
                              200, // Adjust this width as needed, or use MediaQuery for dynamic width
                          child: Text(
                            meal.name,
                            overflow: TextOverflow
                                .ellipsis, // Add ellipsis for long text
                          ),
                        ),
                        // OR: Use Flexible/Expanded if there are other widgets in the row
                        // child: Row(
                        //   children: [
                        //     Flexible(
                        //       child: Text(
                        //         meal.name,
                        //         overflow: TextOverflow.ellipsis,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedMealId = val),
                decoration: _buildDropdownDecoration('Select Meal to Swap'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedMealId == null
                      ? null
                      : () async {
                          await _apiService.swapMeal(
                            deliveryId,
                            item.id,
                            selectedMealId!,
                          );
                          Navigator.pop(context);
                          _reloadData();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
