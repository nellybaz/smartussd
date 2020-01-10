import 'dart:core';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kene/components/CustomFloatingButton.dart';
import 'package:kene/components/bottom_navigation.dart';
import 'package:kene/components/input_container.dart';
import 'package:kene/components/loader.dart';
import 'package:kene/database/db.dart';
import 'package:kene/pages/settings.dart';
import 'package:kene/utils/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kene/utils/stylesguide.dart';
import 'package:kene/widgets/bloc_provider.dart';
import 'package:kene/widgets/custom_nav.dart';
import 'package:kene/components/service_item.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';

//
// TODO: Support country selection, multiple input and map structure of services
// TODO: session count for users
// TODO: make swipe for items with children open the children
// TODO: submit button inactive when fields are empty
// TODO: edit saved accounts
//

class Services extends StatefulWidget {
  final carrierId;
  final primaryColor;
  final carrierTitle;
  final analytics;

  Services(
      {this.carrierId, this.primaryColor, this.carrierTitle, this.analytics});
  @override
  State<StatefulWidget> createState() {
    return _ServicesState();
  }
}

class _ServicesState extends State<Services> with TickerProviderStateMixin {
  static const platform = const MethodChannel('com.kene.momouusd');

  // Scroll NestedScrollView when listView is scrolled
  scrollListener() {
    var innerScrollPos = _listViewController.offset;
//    _scrollController.animateTo(innerScrollPos/2, duration: Duration(microseconds: 10), curve: Curves.linear);
  _scrollController.jumpTo(innerScrollPos/2);
  }

  ScrollController _listViewController = new ScrollController();

  TextEditingController _amountController = TextEditingController();
  TextEditingController _recipientController = TextEditingController();

  bool showSubmit = false;

  String uid = "";

  String locale = "en";

  ///default values that are changed when option clicked

  List navigationStack = [];
  String collectionURL = "";
  List headTitleStack = [];
  String codeToSend = "";
  bool needsContact = false;
  bool needsRecipient = false;
  String recipientLabel = "";
  int optionID = 0;
  bool showActionSection = false;
  String serviceLabel = "";
  bool canSaveLabels;
  bool needsAmount;
  bool requiresCamera;
  bool isCardPinNext = false;
  bool cameraBtnClicked = false;
  bool hasChildren = false;
  String serviceDescription;
  String pinFound = "";
  String childrenValue = "Select";
  String parentID = "";
  List<dynamic> savedAccounts = [];

  List<DocumentSnapshot> backupServicesList = [];
  Firestore fireStoreInstance;



//  var _labelFormKey = GlobalKey<FormState>();
//  TextEditingController _labelController = TextEditingController();
  KDB db = KDB();

  // Add listener on recipient Input to aid submit button display
  // Initialize headerTitle stack to the service title
  // Set the authenticated user id for accounts checking
  // Set initial collection Url to the service title

  ScrollController _scrollController;

  listener() {
    if (_scrollController.offset >= 45) {
      _scrollController.jumpTo(45);
    }
  }

  @override
  void initState() {
    super.initState();


    fireStoreInstance = Firestore.instance;

    _scrollController = ScrollController(initialScrollOffset: 0.0);
    _scrollController.addListener(listener);

    print("analytics is==========>>>>");
    print(widget.analytics);

    // Send analytics on page load/initialize
    sendAnalytics(widget.analytics, "ServicesPage_Open", null);


    var tmpHeader = [widget.carrierTitle];
    setState(() {
      headTitleStack = tmpHeader;
    });
    _listViewController.addListener(scrollListener);
    FirebaseAuth.instance.currentUser().then((u) {
      if (u != null) {
        setState(() {
          uid = u.uid;
        });
      }
    });

    String initialCollection = "services/${widget.carrierId}/services";
    navigationStack.add(initialCollection);
    setState(() {
      collectionURL = initialCollection;
    });
  }

  @override
  Widget build(BuildContext context) {


    var appBloc;

    appBloc = BlocProvider.of(context);

    appBloc.localeOut.listen((data) {
      if(mounted){
        setState(() {
          locale = data != null ? data : locale;
        });
      }
    });


    return Scaffold(
        bottomNavigationBar: CustomBottomNavigation(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: CustomFloatingButton(pageData: {}, analytics: widget.analytics, locale: locale,),
        body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, bool isScrolled) {
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.175,
                    elevation: 14,
                    pinned: true,
                    floating: true,
                    centerTitle: true,
                    forceElevated: isScrolled,
                    actions: <Widget>[
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                              context, CustomPageRoute(navigateTo: Settings(analytics: widget.analytics,)));
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                    title: AutoSizeText(
                      "Nokanda",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: buttonTextFamily,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                    ),
                    backgroundColor: widget.primaryColor,
                    leading: navigationStack.length > 1 || showActionSection
                        ? IconButton(
                            onPressed: () {
                              if (!showActionSection) {
                                navigationStack.removeLast();

                                setState(() {
                                  collectionURL = navigationStack[
                                      navigationStack.length - 1];
                                });
                              }
                              headTitleStack.removeLast();
                              var ht2 = headTitleStack;
                              setState(() {
                                serviceDescription = "";
                                headTitleStack = ht2;
                                showActionSection = false;
                                _amountController.text = "";
                                _recipientController.text = "";
                                cameraBtnClicked = false;
                              });
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                        : IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                          color: widget.primaryColor,
//                          border: Border.all(),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              "${headTitleStack[headTitleStack.length - 1]}",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ];
              },
              body: Container(
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.175,
                      decoration: BoxDecoration(
                          color: widget.primaryColor,
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
//
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical:20.0, horizontal: 0),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          // MediaQuery.of(context).size.width - 40,
                          height: MediaQuery.of(context).size.height * 0.75,
                          decoration: BoxDecoration(
                              color: Color(0xfff6f7f9),
                              borderRadius: BorderRadius.circular(40)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: ListView(
                              controller: _listViewController,
                              children: <Widget>[
                                !showActionSection
                                    ? fetchServices()
                                    : InputActionContainer(
                                        primaryColor: widget.primaryColor,
                                        analytics: widget.analytics,
                                        carrierTitle: widget.carrierTitle),
//                        actionContainer(),
                                SizedBox(
                                  height: 100,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )));
  }

  /// Receives collection url and fetches children
  StreamBuilder fetchServices() {
    return StreamBuilder(
      stream: fireStoreInstance
          .collection("$collectionURL")
          .where("isActive", isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: NLoader());
        }
        snapshot.data.documents.sort((DocumentSnapshot a, DocumentSnapshot b) =>
            getServiceOrderNo(a).compareTo(getServiceOrderNo(b)));
        return snapshot.data.documents.length > 0 ? Column(
            children: displayServices(
                snapshot.data.documents) //display the services fetched
            )
            : backupServicesList.length > 0 ? Column(
            children: displayServices(
                backupServicesList) //display the services fetched
        ):

        GestureDetector(
          onTap: (){
            getServices();
          },
          child: Container(
            decoration: BoxDecoration(
//              border: Border.all()
            ),
            height: MediaQuery.of(context).size.height * 0.4,
            width: MediaQuery.of(context).size.width * 0.4,
            child: Icon(Icons.refresh, size: 40),
          ),
        );
      },
    );
  }

  int getServiceOrderNo(x) {
    return x['orderNo'];
  }

  getServices() async{
    print("get new services refresh hit");
    var res = await fireStoreInstance
        .collection("$collectionURL")
        .where("isActive", isEqualTo: true)
        .getDocuments();

    if(res.documents.length > 0){

      res.documents.sort((DocumentSnapshot a, DocumentSnapshot b) =>
          getServiceOrderNo(a).compareTo(getServiceOrderNo(b)));

      setState(() {
        backupServicesList = res.documents;
      });
    }
  }

// Function called from serviceItem class
// Receives motive from child and performs actions accordingly
  serviceActions(String url, int motive, Map<String, dynamic> data) {
    if (motive == 0) {

      // If service has children, this condition is met
      if (url.isNotEmpty) {
        var tmp = navigationStack;
        tmp.add(collectionURL + url);
        setState(() {
          collectionURL = collectionURL + url;
          navigationStack = tmp;

        });
      }
    }

    // If service has no input and no children, condition is met
    else if (motive == 1) {

      sendCode(platform, data['code'], _amountController.text,
          _recipientController.text, context);
    }

    // If leaf service [has input and no children], condition is met
    else {

      setState(() {
        showActionSection = true;
      });
      _listViewController.animateTo(0,
          duration: Duration(milliseconds: 10), curve: Curves.easeIn);
    }

    sendAnalytics(
        widget.analytics, widget.carrierTitle + "_" + data['label'], null);

    // Check for name and update the headerText
    var hT = headTitleStack;
    if(data['name_map'] != null){
      hT.add(data['name_map'][locale] != null ? data['name_map'][locale]:data['name_map']["en"]);

      setState(() {
        headTitleStack = hT;
      });
    }
    else if (data['name'] != null) {
      hT.add(data['name']);

      setState(() {
        headTitleStack = hT;
      });
    }
  }

  // Receive list data and create a service item out the data and returns list of service data
  displayServices(lists) {
    List<Widget> tmp = [];
    for (var list in lists) {
      if (list['label'] == "LoadAirtime" && Platform.isIOS) {
//        continue;
        tmp.add(
          ServiceItem(
            backgroundColor: Colors.white,
            icon: list['icon'],
            name: list['name'],
            nameMap: list['name_map'],
            label: list['label'],
            needsContact: list['needsContact'],
            needsRecipient: list['needsRecipient'],
            requiresInput: list['requiresInput'],
            codeToSend: list['code'],
            recipientLabel: list['recipientLabelMap'] != null && list['recipientLabelMap'][locale] ==  null ? list['recipientLabelMap']["en"]
                : list['recipientLabelMap'] != null && list['recipientLabelMap'][locale] !=  null ? list['recipientLabelMap'][locale] : list['recipientLabel'],
            canSaveLabels: list['canSaveLabels'],
            needsAmount: list['needsAmount'],
            requiresCamera: list['requiresCamera'],
            serviceDescription: list['serviceDescription'],
            hasChildren: list['hasChildren'],
            parentID: list.documentID,
            serviceActions: serviceActions,
            primaryColor:widget.primaryColor,
            needsScan: list["needsScan"],
            carrierID: widget.carrierId,
//            favouritesMap: _favouritesMap,
          ),
        );
      } else {
        tmp.add(
          ServiceItem(
            backgroundColor: Colors.white,
            icon: list['icon'],
            name: list['name'],
            nameMap: list['name_map'],
            label: list['label'],
            needsContact: list['needsContact'],
            needsRecipient: list['needsRecipient'],
            requiresInput: list['requiresInput'],
            codeToSend: list['code'],
            recipientLabel: list['recipientLabelMap'] != null && list['recipientLabelMap'][locale] ==  null ? list['recipientLabelMap']["en"]
                : list['recipientLabelMap'] != null && list['recipientLabelMap'][locale] !=  null ? list['recipientLabelMap'][locale] : list['recipientLabel'],
            canSaveLabels: list['canSaveLabels'],
            needsAmount: list['needsAmount'],
            requiresCamera: list['requiresCamera'],
            serviceDescription: list['serviceDescription'],
            hasChildren: list['hasChildren'],
            parentID: list.documentID,
            serviceActions: serviceActions,
            primaryColor: widget.primaryColor,
            needsScan: list["needsScan"],
            carrierID: widget.carrierId,
//            favouritesMap: _favouritesMap,
          ),
        );
      }
    }

    return tmp;
  }



}
