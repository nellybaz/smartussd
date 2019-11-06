import 'dart:core';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kene/components/input_container.dart';
import 'package:kene/database/db.dart';
import 'package:kene/pages/cariers.dart';
import 'package:kene/pages/settings.dart';
import 'package:kene/utils/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kene/widgets/custom_nav.dart';
import 'package:kene/components/service_item.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';


///
/// TODO: Support languages, country selection, multiple input and map structure of services
/// TODO: fix the ios focus bug == >  check
/// TODO: add service name to events ====> check
/// TODO: Tracking amounts  ====> check
/// TODO: Add success screen after submit button ===> check
///


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
  scrollListener() {
  }

  ScrollController _listViewController = new ScrollController();

  TextEditingController _amountController = TextEditingController();
  TextEditingController _recipientController = TextEditingController();

  bool showSubmit = false;


  String uid = "";

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
  String serviceLable = "";
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

  var _labelFormKey = GlobalKey<FormState>();
  TextEditingController _labelController = TextEditingController();
  KDB db = KDB();


  // Add listener on recipient Input to aid submit button display
  // Initialize headerTitle stack to the service title
  // Set the authenticated user id for accounts checking
  // Set initial collection Url to the service title


  @override
  void initState() {
    super.initState();

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
    return Scaffold(
        body: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 40,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    //  decoration: BoxDecoration(
                    //    border: Border.all()
                    //  ),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Align(
                              alignment: Alignment.topLeft,
                              child: navigationStack.length > 1 ||
                                      showActionSection
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
                                        Icons.arrow_back_ios,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            CustomPageRoute(
                                                navigateTo: Carriers()));
                                      },
                                      icon: Icon(
                                        Icons.home,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    )),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.center,
                            child: AutoSizeText(
                              "Nokanda",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(context,
                                    CustomPageRoute(navigateTo: Settings()));
                              },
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children:[
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),

                      Expanded(
                        flex:4,
                        child:Align(
                          alignment: Alignment.center,
                          child: Text(
                            "${headTitleStack[headTitleStack.length - 1]}",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        )
                      ),

                      Expanded(
                        flex: 1,
                        child: serviceDescription != null && serviceDescription.isNotEmpty ? GestureDetector(
                          child: IconButton(icon: Icon(Icons.info_outline, color: Colors.white,), onPressed: (){
                            Platform.isIOS ? 
                                showCupertinoDialog(context: context, builder: (context){
                                  return CupertinoAlertDialog(
                                    title: Center(
                                      child: Text("Info"),
                                    ),
                                    content: Text("$serviceDescription "),
                                    actions: <Widget>[
                                      CupertinoButton(child: Text("Close"), onPressed: (){
                                        Navigator.pop(context);
                                      })
                                    ],
                                  );
                                })
                                
                                :
                            
                            showDialog(context: context, builder: (context){
                              return AlertDialog(
                                title: Center(
                                  child: Text("Info"),
                                ),
                                content: Text("$serviceDescription"),
                              );
                            });
                          }),
                        ):
                        Container(),
                      ),
                    ]
                  )
                ],
              ),
            ),
            Positioned(
              top: 130,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                      color: Color(0xffE3E1E1),
                      borderRadius: BorderRadius.circular(40)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ListView(
                      controller: _listViewController,
                      children: <Widget>[
                        !showActionSection
                            ? fetchServices()
                            : InputActionContainer(primaryColor: widget.primaryColor, analytics: widget.analytics, carrierTitle: widget.carrierTitle),
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
    ));
  }


  /// Receives collection url and fetches children
  StreamBuilder fetchServices() {
    return StreamBuilder(
      stream: Firestore.instance
          .collection("$collectionURL")
          .where("isActive", isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: Text("Loading services"));
        }
        snapshot.data.documents.sort((DocumentSnapshot a, DocumentSnapshot b) =>
            getServiceOrderNo(a).compareTo(getServiceOrderNo(b)));
        return Column(
            children:
            displayServices(snapshot.data.documents) //display the services fetched
        );
      },
    );
  }

  int getServiceOrderNo(x) {
    return x['orderNo'];
  }


// called from serviceItem class
// receives motive from child and performs actions accordingly
//  _listViewController
  serviceActions(String url, int motive, Map<String, dynamic> data){

  if(motive == 0){  // service has children
    if (url.isNotEmpty){
//    print({"url":url, "motive":motive, "data":data});
      var tmp = navigationStack;
      tmp.add(collectionURL + url);
      setState(() {
        collectionURL = collectionURL + url;
        navigationStack = tmp;

//        fetchServices(collectionURL);
      });
    }
  }
  else if(motive == 1){ // has no input and no children
    sendCode(platform, data['code'], _amountController.text, _recipientController.text, context);
  }

  else{ // leaf service [has input and no children]


    setState(() {
      showActionSection = true;
    });
    _listViewController.animateTo(0,
        duration: Duration(milliseconds: 10), curve: Curves.easeIn);
  }

  sendAnalytics(widget.analytics, widget.carrierTitle + "_"+data['label'], null);

  // check for name and update the headerText
  var hT = headTitleStack;
  if (data['name'] != null) {
    hT.add(data['name']);

    setState(() {
      headTitleStack = hT;
    });
  }

  }

  // Receives list data, creates a service item out the data and returns list of service data
  displayServices(lists) {
    List<Widget> tmp = [];
    for (var list in lists) {

      if (list['label'] == "LoadAirtime" && Platform.isIOS) {
        continue;
      } else {
        tmp.add(
//          buildServiceListItem(list),
        ServiceItem(
          backgroundColor: Colors.white,
          icon:list['icon'],
          name:list['name'],
          nameMap: list['name_map'],
          label:list['label'],
          needsContact: list['needsContact'],
          needsRecipient: list['needsRecipient'],
          requiresInput: list['requiresInput'],
          codeToSend: list['code'],
          recipientLabel:list['recipientLabel'],
          canSaveLabels:list['canSaveLabels'],
          needsAmount:list['needsAmount'],
          requiresCamera:list['requiresCamera'],
          serviceDescription:list['serviceDescription'],
          hasChildren:list['hasChildren'],
          parentID:list.documentID,
          serviceActions: serviceActions,


        ),
        );
      }
    }

    return tmp;
  }
}
