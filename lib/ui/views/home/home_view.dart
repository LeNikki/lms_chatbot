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
    return Scaffold(
                backgroundColor: viewModel.backgroundColor,
                appBar: AppBar(
                  backgroundColor: viewModel.primaryColor,
                  title: Text(viewModel.role.isEmpty ? "" : "Home (${viewModel.role})"),
                  actions: [
                    if (viewModel.isUploading)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                            final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
                            if (renderBox == null || overlay == null) return;
                            final bellPosition = renderBox.localToGlobal(
                              Offset(renderBox.size.width - 56, kToolbarHeight),
                              ancestor: overlay,
                            );
                            showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                bellPosition.dx,
                                bellPosition.dy,
                                bellPosition.dx + 1,
                                bellPosition.dy + 1,
                              ),
                              items: [
                                PopupMenuItem<String>(
                                  enabled: false,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          viewModel.uploadStatus.replaceAll('\n', ' '),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
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
                      UploadButton(context, viewModel)
                    ],
                  ),
                ),
                body: Stack(
                  children: [
                    Column(
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MarkdownBody(
                                          data: msg['text'],
                                          selectable: true,
                                          softLineBreak: true,
                                          styleSheet: MarkdownStyleSheet(
                                            p: TextStyle(
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 16,
                                            ),
                                            h1: TextStyle(
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            h2: TextStyle(
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            strong: TextStyle(
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            listBullet: TextStyle(
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
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

  Widget UploadButton(BuildContext context, HomeViewModel viewModel) {
    return Visibility(
                        visible: viewModel.role.isNotEmpty && viewModel.role != "student",
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: GestureDetector(
                              onTap: viewModel.isUploading
                                  ? null
                                  : () {
                                      viewModel.processPdfForKnowledgeBase(context);
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: viewModel.isUploading
                                        ? Colors.grey
                                        : Colors.blue),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (viewModel.isUploading)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (viewModel.isUploading)
                                      const SizedBox(width: 8),
                                    Text(viewModel.isUploading
                                        ? "Uploading..."
                                        : "Upload Learning Material"),
                                  ],
                                ),
                              )),
                        ));
  }

   @override
    void onViewModelReady(HomeViewModel viewModel) {
      viewModel.init(); 
    }

   @override
    HomeViewModel viewModelBuilder(
    BuildContext context,
    ) =>
      HomeViewModel();
}
