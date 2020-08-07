part of 'pages.dart';

class ChatScreenPage extends StatefulWidget {
  final User receiver;
  final User sender;
  ChatScreenPage({this.receiver, this.sender});

  @override
  _ChatScreenPageState createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  ImageUploadProvider _imageUploadProvider;
  @override
  Widget build(BuildContext context) {
    _imageUploadProvider = Provider.of<ImageUploadProvider>(context);
    return WillPopScope(onWillPop: () async {
      context.bloc<PageBloc>().add(GoToMainPage());
      return;
    }, child: BlocBuilder<UserBloc, UserState>(builder: (context, userState) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                context.bloc<PageBloc>().add(GoToMainPage());
              },
            ),
            title: Column(
              children: [
                Text(widget.receiver.fullName,
                    style: whiteTextFont.copyWith(fontSize: 18)),
                Text(
                  widget.receiver.job,
                  style: greyTextFont.copyWith(fontSize: 14),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Container(
                  width: 48,
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                      widget.receiver.profileImage,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Flexible(
                child: ChatMessageScreen(
              receiver: widget.receiver,
              sender: widget.sender,
            )),
            _imageUploadProvider.getViewState == ViewState.LOADING
                ? Container(
                    alignment: Alignment.centerRight,
                    margin: EdgeInsets.only(right: 20),
                    child: CircularProgressIndicator(
                      backgroundColor: accentColor2,
                    ),
                  )
                : Container(),
            ChatBottomControl(
              receiver: widget.receiver,
              sender: widget.sender,
            ),
          ],
        ),
      );
    }));
  }
}

class ChatMessageScreen extends StatefulWidget {
  final User sender;
  final User receiver;

  ChatMessageScreen({this.sender, this.receiver});

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  @override
  Widget build(BuildContext context) {
    String _currentUserId = widget.sender.id.toString();
    return StreamBuilder(
        stream: Firestore.instance
            .collection("messages")
            .document(_currentUserId)
            .collection(widget.receiver.id)
            .orderBy("timeStamp", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.data == null) {
            return Center(
              child: SpinKitFadingCircle(
                color: accentColor2,
                size: 30,
              ),
            );
          }

          return ListView.builder(
              padding: EdgeInsets.all(defaultMargin),
              itemCount: snapshot.data.documents.length,
              reverse: true,
              itemBuilder: (context, index) {
                return ChatMessageItem(
                    snapshot.data.documents[index], _currentUserId);
              });
        });
  }
}

class ChatMessageItem extends StatefulWidget {
  final DocumentSnapshot documentSnapshot;
  final String _currentUserId;
  ChatMessageItem(this.documentSnapshot, this._currentUserId);

  @override
  _ChatMessageItemState createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  @override
  Widget build(BuildContext context) {
    Message _message = Message.fromMap(widget.documentSnapshot.data);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 15),
      child: Container(
        alignment: (_message.senderId == widget._currentUserId)
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: (_message.senderId == widget._currentUserId)
            ? senderLayout(_message)
            : receiverLayout(_message),
      ),
    );
  }

  // to show the message from the sender
  Widget senderLayout(Message message) {
    Radius messageRadius = Radius.circular(10);
    String time = DateFormat.jm().format(message.timeStamp.toDate());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
              color: accentColor1,
              borderRadius: BorderRadius.only(
                bottomLeft: messageRadius,
                topLeft: messageRadius,
                bottomRight: messageRadius,
              )),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: getMessage(message),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            time,
            style: greyTextFont,
          ),
        ),
      ],
    );
  }

  // to show the message from the receiver
  Widget receiverLayout(Message message) {
    Radius messageRadius = Radius.circular(10);
    return Container(
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
          color: accentColor2,
          borderRadius: BorderRadius.only(
            bottomLeft: messageRadius,
            topRight: messageRadius,
            bottomRight: messageRadius,
          )),
      child: Padding(padding: EdgeInsets.all(10), child: getMessage(message)),
    );
  }

// Send Image
  getMessage(Message message) {
    return message.type == "image"
        ? CachedImage(
            imageUrl: message.photoUrl,
          )
        : Text(
            message.message,
            style: blackTextFont.copyWith(fontSize: 16),
          );
  }
}

class ChatBottomControl extends StatefulWidget {
  final User receiver;
  final User sender;

  ChatBottomControl({this.receiver, this.sender});

  @override
  _ChatBottomControlState createState() => _ChatBottomControlState();
}

class _ChatBottomControlState extends State<ChatBottomControl> {
  TextEditingController textChatController = TextEditingController();

  bool isWriting = false;

  setWritingTo(bool val) {
    setState(() {
      isWriting = val;
    });
  }

  ImageUploadProvider _imageUploadProvider;

  @override
  Widget build(BuildContext context) {
    final String receiverName = widget.receiver.fullName;
    _imageUploadProvider = Provider.of<ImageUploadProvider>(context);
    return Container(
      margin: EdgeInsets.only(left: 6, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              maxLines: 5,
              minLines: 1,
              controller: textChatController,
              style: blackTextFont,
              onChanged: (val) {
                (val.length > 0 && val.trim() != "")
                    ? setWritingTo(true)
                    : setWritingTo(false);
              },
              decoration: InputDecoration(
                hintText: "Tulis pesan untuk dr.$receiverName",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
            ),
          ),
          // *image button
          (isWriting)
              ? Container()
              : Container(
                  padding: EdgeInsets.all(0),
                  width: 32,
                  child: IconButton(
                      icon: Icon(
                        Icons.image,
                        size: 28,
                        color: mainColor,
                      ),
                      onPressed: () async {
                        File selectedImage = await getImage();
                        uploadImageMessage(
                            image: selectedImage,
                            receiverId: widget.receiver.id,
                            senderId: widget.sender.id,
                            imageUploadProvider: _imageUploadProvider);
                      })),
          // *camera button
          (isWriting)
              ? Container()
              : Container(
                  padding: EdgeInsets.all(0),
                  width: 32,
                  child: IconButton(
                      icon: Icon(
                        Icons.camera_alt,
                        size: 28,
                        color: mainColor,
                      ),
                      onPressed: () async {
                        File selectedImage = await getImageCamera();
                        uploadImageMessage(
                            image: selectedImage,
                            receiverId: widget.receiver.id,
                            senderId: widget.sender.id,
                            imageUploadProvider: _imageUploadProvider);
                      })),
          // *vidcall button
          (isWriting)
              ? Container()
              : Container(
                  padding: EdgeInsets.all(0),
                  width: 38,
                  child: IconButton(
                      icon: Icon(
                        Icons.video_call,
                        size: 32,
                        color: mainColor,
                      ),
                      onPressed: () {
                        CallUtils.dial(
                          context: context,
                          userCaller: widget.sender,
                          userReceiver: widget.receiver,
                        );
                        bool hasCallMade = CallUtils.hasCallMade;
                        if (hasCallMade) {
                          Call call = CallUtils.call;
                          context
                              .bloc<PageBloc>()
                              .add(GoToCallScreenPage(call: call));
                        }
                      }),
                ),
          // *send button
          (isWriting)
              ? Container(
                  width: 38,
                  margin: EdgeInsets.only(left: 10),
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: mainColor),
                  child: IconButton(
                      icon: Icon(
                        Icons.send,
                        size: 18,
                        color: accentColor2,
                      ),
                      onPressed: () {
                        sendMessage();
                      }),
                )
              : Container(),
          SizedBox(
            width: 8,
          )
        ],
      ),
    );
  }

  void sendMessage() {
    var text = textChatController.text;
    Message _message = Message(
      receiverId: widget.receiver.id,
      senderId: widget.sender.id,
      message: text,
      timeStamp: Timestamp.now(),
      type: 'text',
    );

    // when send message tap
    setState(() {
      isWriting = false;
      textChatController.text = "";
    });

    MessageServices.addMessageToDb(_message, widget.sender, widget.receiver);
  }
}
