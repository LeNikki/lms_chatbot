import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lms_chatbot/ui/widgets/typing_widget.dart';
import 'package:stacked/stacked.dart';
import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ){
    return  viewModel.isBusy
            ? UploadingLearningMaterials(viewModel)
            : Scaffold(
                backgroundColor: viewModel.backgroundColor,
                appBar: AppBar(
                  backgroundColor: viewModel.primaryColor,
                  title: Text("Home (${viewModel.role})"),
                ),
                drawer: Drawer(
                  backgroundColor: viewModel.drawerColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: viewModel.primaryColor,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        viewModel.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        viewModel.role.toUpperCase(),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text("Logout"),
                        onTap: viewModel.logout,
                      ),
                      UploadButton(viewModel)
                    ],
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: viewModel.backgroundColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount:
                              viewModel.messages.length + (viewModel.isAiTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (viewModel.isAiTyping && index == viewModel.messages.length) {
                              return const Align(
                                alignment: Alignment.centerLeft,
                                child: TypingBubble(),
                              );
                            }
                            final msg = viewModel.messages[index];
                            final isUser = msg['isUser'] == true;

                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isUser ? viewModel.primaryColor : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: MarkdownBody(
                                  data: msg['text'],
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                      fontSize: 16,
                                    ),
                                    h1: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    strong: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    listBullet: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    ChatField(context, viewModel),
                  ],
                ),
              );
    
  }

  Container ChatField(BuildContext context, HomeViewModel viewModel) {
    return Container(
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
                            controller: viewModel.messageController,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: viewModel.primaryColor),
                          onPressed: viewModel.sendMessage,
                        ),
                      ],
                    ),
                  );
  }

  Visibility UploadButton(HomeViewModel viewModel) {
    return Visibility(
                        visible: viewModel.role != "student",
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: GestureDetector(
                              onTap: () {
                                viewModel.processPdfForKnowledgeBase();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.blue),
                                child: Text("Upload Learning Material"),
                              )),
                        ));
  }

  Material UploadingLearningMaterials(HomeViewModel viewModel) {
    return Material(
              child: Stack(
              children: [
                if (viewModel.isBusy)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Uploading learning materials...\nPlease wait.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ));
  }

   @override
    HomeViewModel viewModelBuilder(
    BuildContext context,
    ) =>
      HomeViewModel();
}
