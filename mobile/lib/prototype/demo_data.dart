class DemoGroup {
  DemoGroup(this.name, this.participants, {this.hasSampleBill = false});

  final String name;
  final List<String> participants;
  final bool hasSampleBill;
  String? self;
}

List<DemoGroup> demoGroups() => [
  DemoGroup('Friday Dinner', ['Alex', 'Bea', 'Chan'], hasSampleBill: true)
    ..self = 'Alex',
  DemoGroup('Weekend Trip', ['Alex', 'Taylor'])..self = 'Alex',
];
