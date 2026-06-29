import 'package:flutter/material.dart';
import 'package:lms_chatbot/ui/common/ui_helpers.dart';
import 'package:lms_chatbot/ui/widgets/typing_widget.dart';
import 'package:stacked/stacked.dart';
import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      onViewModelReady: (vm) async => await vm.init(),
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: vm.backgroundColor,
          appBar: AppBar(
            backgroundColor: vm.primaryColor,
            title: Text("Home (${vm.role})"),
          ),
          drawer: Drawer(
            backgroundColor: vm.drawerColor,
            child: Column(
              children: [
                const SizedBox(height: 60),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: vm.primaryColor,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  vm.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  vm.role.toUpperCase(),
                  style: const TextStyle(color: Colors.black54),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: vm.logout,
                ),
                Visibility(
                visible: vm.role!="student",
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: GestureDetector(
                      onTap: () {
                        vm.processPdfForKnowledgeBase();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blue),
                        child: Text("Upload Learning Material"),
                      )),
                )
                )
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: vm.backgroundColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: vm.messages.length + (vm.isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (vm.isAiTyping && index == vm.messages.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: TypingBubble(),
                            );
                          }
                      final msg = vm.messages[index];
                      final isUser = msg['isUser'] == true;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? vm.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text'],
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: vm.messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: vm.primaryColor),
                      onPressed: vm.sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
