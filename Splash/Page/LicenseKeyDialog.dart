import 'dart:io';
import 'package:USB_Share/ErrorLog/Model/errorLogModel.dart';
import 'package:USB_Share/ErrorLog/Service/errorLog.dart';
import 'package:USB_Share/Util/common_ui.dart';
import 'package:USB_Share/Util/constant.dart';
import 'package:USB_Share/Util/hive_helper.dart';
import 'package:USB_Share/Util/page_router.dart';
import 'package:USB_Share/Util/palette.dart';
import 'package:USB_Share/Util/session.dart';
import 'package:USB_Share/Util/sizing.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CheckLicenseAuthentication extends StatefulWidget {
  final bool isRenewal;
  const CheckLicenseAuthentication({super.key, required this.isRenewal});

  @override
  State<CheckLicenseAuthentication> createState() =>
      _CheckLicenseAuthenticationState();
}

class _CheckLicenseAuthenticationState
    extends State<CheckLicenseAuthentication> {
  List<ErrorLogModel> errorLog = [];
  final errorLogService = ErrorLogService();
  bool showErrorMsg = false;
  final scrollController = ScrollController();
  bool isChecked = false;
  bool showAlert = false;
  bool startLicenseAuthentication = false;

  final TextEditingController _passkey = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return startLicenseAuthentication
        ? licenseSubmission()
        : licenseAgreement();
  }

  licenseAgreement() {
    return AlertDialog(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'CARDIO LICENSE AGREEMENT',
            style: TextStyle(
                fontSize: Sizing().height(2, 4), fontWeight: FontWeight.w600),
          ),
          SizedBox(
            height: Sizing().height(5, 5),
          ),
          Text(
            'Kindly read the following license agreement before continuing.',
            style: TextStyle(
                fontSize: Sizing().height(2, 4), fontWeight: FontWeight.w400),
          ),
        ],
      ),
      content: Container(
        decoration: BoxDecoration(border: Border.all(color: greyColor)),
        child: RawScrollbar(
          thumbVisibility: true,
          minThumbLength: 1,
          thickness: 4,
          radius: Radius.circular(5),
          thumbColor: Colors.grey[400],
          trackColor: Colors.grey[400],
          controller: scrollController,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Sizing.width(5, 4),
                  vertical: Sizing().height(3, 4)),
              child: Text('''SOFTWARE LICENSE AGREEMENT
VAANAM TECHNOLOGIES PRIVATE LIMITED AND OUR CUSTOMERS ARE BOUND BY THIS SOFTWARE LICENSE AGREEMENT
PLEASE READ THIS LICENSE AGREEMENT CAREFULLY. THIS LICENSE AGREEMENT IS A LEGAL AGREEMENT BETWEEN YOU AND VAANAM TECHNOLOGIES PRIVATE LIMITED. HEREIN KNOWN AS VTPL, AND YOU (AS DEFINED BELOW). YOU ARE AGREEING THAT YOU HAVE READ ALL OF THE TERMS AND CONDITIONS SET FORTH BELOW, UNDERSTAND ALL OF THE TERMS AND CONDITIONS OF THIS LICENSE AGREEMENT AND AGREE TO BE BOUND BY THE TERMS AND CONDITIONS OF THIS LICENSE AREEMENT. AS USED IN THIS AGREEMENT, “YOU” MEANS THE PERSON OR COMPANY SEEKING TO ACQUIRE THE RIGHTS AND OBLIGATIONS UNDER THIS LICENSE AGREEMENT AND, WITH RESPECT TO ANY COMPANY EXPRESSLY EXCLUDES ITS PARENTS, SUBSIDIARIES AND AFFILIATES. ANY PERSON ENTERING INTO THIS LICENSE AGREEMENT ON BEHALF OF A COMPANY, HEREBY RESPRESENTS THAT SUCH PERSON: (1) IS AN EMPLOYEE OR AGENT OF SUCH COMPANY; AND (2) HAS THE AUTHORITY TO ENTER INTO
THIS LICENSE AGREEMENT ON BEHALF OF SUCH COMPANY.
********WARNING*********
VTPL IS WILLING TO LICENSE THE SOFTWARE TO YOU ONLY UPON THE CONDITION THAT YOU ACCEPT ALL OF THE TERMS AND CONDITIONS CONTAINED IN THIS AGREEMENT.
I. OWNERSHIP; LICENSE GRANT
A. As between the parties, VTPL owns all right, title and interest in and to the computer software and associated media and materials including any related documentation such as standard training, user or reference manuals delivered in machine readable form or online at the Vaanam Technologies Private Limited  and/or Cardio website (collectively, the “SOFTWARE”) and any and all patents, copyrights, moral rights, trademarks, trade secrets and any other form of intellectual property rights recognized in any jurisdiction, including applications and registrations for any of the foregoing embodied therein (“Intellectual Property Rights”). There are no implied licenses and VTPL retains all rights not expressly granted to YOU in this AGREEMENT. All corrections, bug fixes, enhancements, updates, additions, or new releases (“Updates”) created by or on behalf of VTPL and provided or made available to YOU as part of the SOFTWARE will, together with all applicable Intellectual Property Rights, be owned by VTPL, but will be included as part of the SOFTWARE for purposes of the license granted to YOU hereunder. 
B. VTPL hereby grants to YOU, and YOU accept, a non-exclusive, non-transferable, non-sublicensable, revocable and limited license to access, use, copy and modify the SOFTWARE, in object code form, only as authorized in Section III of this
AGREEMENT.
II. TRIAL LICENSE; PERMITTED USES
YOU may install, copy, and use trial/developer versions of the SOFTWARE for “as defined” period of time solely for the purposes of evaluation, demonstration, trials and training as well as the design, development, staging and testing of designs, content and web parts on Your development servers, testing servers and/or staging servers.  For purposes of the trial license, the SOFTWARE is in “use” on a computer when it is loaded into temporary memory (e.g., RAM) or installed into permanent memory (e.g., hard disk, CD-ROM, or other storage devise) of that computer and in “use” on a server when installed on any server of Yours, except for a web server that hosts web pages and content that is live or is ready to be delivered for production (a “Production Server”).   All trial/developer versions of the SOFTWARE are subject to the rights, requirements and obligations of this AGREEMENT.
The SOFTWARE is licensed for full use:
VTPL grants to YOU, effective upon completion of delivery and installation of the System, a non-exclusive license to use the applications software owned by VTPL.  No transfer of ownership of this licensed software may be made without the prior written consent of VTPL, which consent may be withheld by VTPL at its discretion. The recipient of the transfer must agree to all the terms of this AGREEMENT as a condition precedent to the transfer of the licensed software. A pro-rated transfer fee will be enforced.  Copyright trademark laws and international treaties, as well as other intellectual property laws and treaties protect the SOFTWARE.  All rights are reserved worldwide. This license shall automatically terminate if you violate any of these restrictions and may be terminated by VTPL at any time.  Upon terminating your viewing of these materials or upon the termination of this license, you must destroy any downloaded materials in your possession whether in electronic or printed format.
III. PROHIBITED USES; MODIFICATIONS
A. You may not, without the prior written permission of VTPL:
·	disassemble, decompile or "unlock", decode or otherwise reverse translate or engineer, or attempt in any manner to reconstruct or discover any source code or underlying algorithms of SOFTWARE which is provided in object code form only or create any derivative works of the SOFTWARE; 
·	use, copy, modify or merge copies of the SOFTWARE and any accompanying documents except as permitted in this AGREEMENT;
·	transfer, rent, lease, or sublicense the SOFTWARE;
·	remove or alter any trademark, logo, copyright or other proprietary notices associated with the SOFTWARE;
·	design, develop or create any modifications, enhancements, derivative works and/or extensions (collectively “Modifications”) to the SOFTWARE; or
·	cause or permit any other party to do any of the foregoing.
B. In the event YOU or any of your employees, consultants or agents design, develop or create any Modifications to the SOFTWARE in violation of this AGREEMENT, and addition to any other remedies that may be available in law, in equity or under this AGREEMENT, all right title and interest in and to such Modifications and all Intellectual Property Rights associated therewith will be the exclusive property of VTPL. You agree to assign, and hereby assign, to VTPL the ownership of all such right, title and interests in such Modifications including, without limitation, all Intellectual Property Rights therein and VTPL shall have the right to obtain and hold same in its own name, without obligation of any kind to YOU. You also agree to execute, acknowledge and deliver to VTPL all documents and do all things VTPL deems necessary or desirable, at your expense, to enable VTPL to obtain and secure its rights to such Modifications anywhere in the World. You agree to secure all necessary rights and obligations from your employees, consultants or agents in order to satisfy the foregoing obligations.
C. You hereby agree to indemnify, hold harmless and defend VTPL, its affiliates and licensors, and each of their respective officers, directors, employees and agents from and against any and all liabilities, damages, losses, costs and expenses (including reasonable attorneys' fees) arising from or related to any demand, claim, action, legal proceeding or allegation that arises or results, either directly or indirectly, from your use and the use by your employees, consultants and agents of the SOFTWARE and any breach by YOU or them of the terms of this AGREEMENT.
VI. PROPRIETARY PROTECTION OF SOFTWARE
A. Reservation of Title. This AGREEMENT does not effect any transfer of title in the SOFTWARE (or any materials furnished or produced in connection with the SOFTWARE), including drawings, diagrams, specifications, input formats, source code, and user manuals. YOU acknowledge that (1) the SOFTWARE (and all materials furnished or produced in connection with the SOFTWARE), including, without limitation, the design, programming techniques, flow charts, source code, and input data formats, contain trade secrets of VTPL, entrusted by VTPL to YOU under this AGREEMENT for use only in the manner expressly permitted hereby, and (2) VTPL claims and reserves all rights and benefits afforded under federal law in the SOFTWARE as an unpublished copyrighted work.
B. Preservation of Secrecy and Confidentiality; Restrictions on Access. YOU agree to protect the SOFTWARE (and all materials furnished or produced in connection with the SOFTWARE as trade secrets of VTPL, and YOU agree to devote its best efforts to ensure that all of your employees, consultants, parent, subsidiaries, affiliates or related parties, who receive, or have access to, protect the SOFTWARE as trade secrets of VTPL. YOU shall not, at any time, disclose such trade secrets to any other person, firm organization, or employee that does not need (consistent with Your right of use hereunder) to obtain access to the SOFTWARE and the materials provided to YOU in connection with the SOFTWARE.
C. Restrictions on Use of Software Generally. Neither the SOFTWARE nor any materials provide to YOU in connection with the SOFTWARE may be copied, reprinted, transcribed, or reproduced, in whole or in part, without the prior written consent of VTPL. YOU shall not in any way modify or enhance the SOFTWARE (or any materials furnished or produced in connection with the SOFTWARE) without the prior written consent of VTPL.
D. Confidential Information. Each party agrees to treat as confidential and keep secret all confidential business and technical information communicated by VTPL to YOU or by YOU to VTPL, including all information contained or embodied in the SOFTWARE and all information, concepts and know-how conveyed to YOU by VTPL with respect to the SOFTWARE. YOU agree to devote its best efforts to ensure that all of Your employees, consultants, parent, subsidiaries, affiliates or related parties, who receive, or have access to, Confidential Information comply with the terms of this AGREEMENT.
Confidentiality however is not applicable to information to which a party had prior knowledge, information that has entered the public domain, or information that is not specifically marked as confidential. Both parties must exercise at least equivalent effort to protect the other party's confidential information, as it would exercise with its own confidential information. EACH PARTY IS HEREBY AUTHORIZED TO MAKE REASONABLE INQUIRIES AND INSPECTIONS TO ENSURE THE OTHER PARTY'S COMPLIANCE HEREWITH.
E. Duration of Duties and Return of Software. The duties and obligations of YOU hereunder shall remain in full force and effect for so long as YOU continue to control, possess, or use the SOFTWARE. YOU shall promptly return the SOFTWARE, together with all materials furnished or produced in connection with the SOFTWARE, upon (1) termination for any reason of this AGREEMENT or Your license of the SOFTWARE or (2) abandonment or other termination of Your control, possession, or use of the SOFTWARE.
V. WARRANTY; DISCLAIMER
A. YOU represent, warrant and covenant that: (i) all of Your employees and consultants will abide by the terms of this AGREEMENT; and (ii) YOU will comply with all applicable laws, regulations, rules, orders and other requirements, now or hereafter in effect, of any applicable governmental authority, in its performance of this AGREEMENT. Notwithstanding any terms to the contrary in this AGREEMENT, YOU will remain responsible for acts or omissions of all employees or consultants of Yours to the same extent as if such acts or omissions were undertaken by YOU. YOU assume responsibility for the selection of the SOFTWARE to achieve your intended results, and for the installation, use, and results obtained from the SOFTWARE.
B. Except with respect to REDISTRIBUTABLES, which are provided "AS IS," without warranty of any kind, VTPL warrants that the SOFTWARE will perform substantially in accordance with its accompanying documentation for a period of thirty (30) days from the Effective Date.
C. Cardio hardware lock is warranted for 30 days from date of purchase subject to the terms and conditions contained herein.
D. The product will be repaired or replaced free of charge by VTPL if, at their sole discretion, it is found to be faulty within the warranty period.
E. This warranty only applies to products sold and distributed within India by VTPL.
F. This warranty only applies if the product has been used in accordance with the manufacturer’s instructions under normal use and with reasonable care (in the opinion of VTPL) subject to all terms and conditions set out in this document and in the handbook.
G. What this warranty does not cover:
(a) Defects or damages resulting from misuse of this product / hardware lock.
(b) Defects or damages from abnormal use, abnormal conditions, improper usage, exposure to moisture, dampness or corrosive environments, unauthorised modifications, unauthorised repair, neglect, rough handling, abuse, accident, alteration, improper installation, incorrect voltage application, food or liquid spillage, acts of God.
(c) Breakage or damage to memory registers or USB sockets unless caused directly by defects in materials or workmanship.
(d) The cost of delivery or transportation of the product to the dealer or officially appointed service person.
(e) Normal wear and tear.
(f) If the Product has been opened, modified or repaired by anyone other than a VTPL or if it is repaired using unauthorised spare parts.
(g) If the serial number or date code has been removed, erased, defaced, altered or are illegible in any way subject to sole judgment of VTPL.
(h) Damage resulting from the use of non-VTPL approved accessories.
VI. LIMITATIONS ON LIABILITY
THE TOTAL LIABILITY OF VTPL AND THE VTPL PARTIES IN THE AGGREGATE TO YOU OR ANY THIRD PARTY ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT, THE SOFTWARE AND SERVICES WILL BE LIMITED TO THE PAYMENTS RECEIVED, WITHIN THE MOST RECENT SIX (6) MONTH PERIOD, FROM YOU, UNDER THIS AGREEMENT.   VTPL AND THE VTPL PARTIES SHALL NOT BE LIABLE FOR INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL OR PUNITIVE DAMAGES OF ANY TYPE ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT, THE SOFTWARE AND/OR SERVICES, WHETHER OR NOT VTPL AND ITS LICENSORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND WHETHER BASED UPON BREACH OF CONTRACT OR TORT (INCLUDING NEGLIGENCE). 
VTPL AND THE VTPL PARTIES SHALL HAVE NO LIABILITY FOR ANY DAMAGES RESULTING FROM ALTERATION, DESTRUCTION OR LOSS OF ANY DATA OR INFORMATION INPUT, GENERATED OR OBTAINED FROM ACCESS AND/OR USE OF THE SOFTWARE AND SERVICES, INCLUDING ANY REPORTS OR NUMERIC RESULTS, WHETHER OR NOT VTPL AND THE VTPL PARTIES HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
VII. No waiver

No relaxation, forbearance, delay or indulgence by either party in enforcing any of the terms and conditions of this Agreement or the granting of time by either party to the other shall prejudice, affect or restrict the rights and powers of that party, nor shall any waiver by either party of any breach of this Agreement operate as a waiver of or in relation to any subsequent or any continuing breach of it.
VIII. SMS
Cardio sends message via your mobile.  You are responsible to messages send using your mobile.  You agree to follow rules and regulations of TRAI for sending SMS.  Cost to SMS is based on your mobile plan and your provider's plan update.  VTPL is not responsible for message sending messages, delivery, content.    
IX. SOFTWARE & HARDWARE REQUIREMENTS
Cardio Pro can be installed on the below listed minimum requirement system.  The software has been tested on ideal condition of the mentioned configuration. VTPL is advised you to install the software on the system which meets the suggested configuration.  VTPL is not liable for the installation issues or failures on using the software, backup and restore failures due to not meeting suggested system configuration. 
Processor: Intel/AMD x86 or x64 processor equivalent
Hard disk: 500MB (Minimum) without dotnet framework; 4GB (recommended)
Memory: 2GB (minimum); 4GB (recommended)
Operating System: Windows 7, 8, 8.1 (recommended) 
Mobile phone: Nokia non smart phones such as 215, 220, 225, 5800, E6, X2
X. JURISDICTION
The parties irrevocably agree that the courts in Coimbatore in the State of Tamilnadu, India have exclusive jurisdiction to settle any dispute or claim that arises out of or in connection with this Agreement or its subject matter or formation (including non-contractual disputes or claims).
XI. MISCELLANEOUS
This AGREEMENT is the entire agreement between YOU and VTPL regarding the subject matter hereof and supersedes all other agreements between us, whether written or oral, relating to this subject matter hereof. In the event of a conflict between this AGREEMENT and any terms of service or other information on the VTPL web-site, this AGREEMENT will prevail. YOU may not transfer Your rights under this AGREEMENT to any third party. If any provision of this AGREEMENT is invalid, illegal, or incapable of being enforced by any rule of law or public policy, all other provisions of this AGREEMENT will nonetheless remain in full force and effect.
IN WITNESS WHEREOF, the parties hereto have caused this Agreement to be executed by their duly authorized representatives effective upon approval of VTPL as marked below.
Vaanam Technologies Private Limited, 			Customer
By: 							By:
Print: 							Print:
Title: 							Title:
Date: 							Date:'''),
            ),
          ),
        ),
      ),
      actions: [
        Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(
                    left: Sizing.width(1, 6), bottom: Sizing().height(0, 1)),
                child: Text(
                  'You must accept the the terms of this agreement before continuing with the License authentication.',
                  style: TextStyle(fontSize: Sizing().height(2, 3.5)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: Sizing.width(1, 2),
              ),
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          checkColor: Colors.white,
                          fillColor: MaterialStateProperty.all(primaryColor),
                          value: isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              isChecked = value!;
                              showAlert = false;
                            });
                          },
                        ),
                      ),
                      Text(
                        'I accept the agreement',
                      ),
                    ],
                  )),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(5)),
                  child: TextButton(
                      onPressed: () async {
                        if (isChecked) {
                          setState(() {
                            startLicenseAuthentication = true;
                          });
                        } else {
                          setState(() {
                            showAlert = true;
                          });
                        }
                      },
                      child: Text(
                        'Next',
                        style: TextStyle(
                            fontSize: Sizing().height(2, 3), color: whiteColor),
                      ))),
            ),
            showAlert
                ? Text('Kindly agree to the terms before continuing.',
                    style: TextStyle(
                      color: Colors.red,
                    ))
                : SizedBox(),
          ],
        )
      ],
    );
  }

  licenseSubmission() {
    return AlertDialog(
      title: Center(
        child: widget.isRenewal
            ? Text(
                'Renew License',
                style: TextStyle(
                    fontSize: Sizing().height(2, 3.5),
                    fontWeight: FontWeight.w500),
              )
            : Text(
                'License Authentication',
                style: TextStyle(
                    fontSize: Sizing().height(2, 3.5),
                    fontWeight: FontWeight.w500),
              ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          passkeyField(),
          showErrorMsg
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Passkey is required',
                      style: TextStyle(
                          fontSize: Sizing().height(2, 3), color: Colors.red),
                    ),
                  ],
                )
              : SizedBox(),
        ],
      ),
      actions: [
        Container(
            decoration: BoxDecoration(
                color: primaryColor, borderRadius: BorderRadius.circular(5)),
            child: TextButton(
                onPressed: () async {
                  try {
                    if (_passkey.text != "") {
                      CommonUi().licenseValidatingLoader(context);
                      String finalKey = '';
                      String macAddress = '';
                      String currentMacAddress = '';
                      String fromDate = '';
                      String toDate = '';
                      finalKey = _passkey.text.trim();
                      Directory pythonFileDir =
                          await Constants.getDataDirectory();
                      String pythonFilePath = pythonFileDir.path;
                      var result = await Process.run('python',
                          ['$pythonFilePath/decryptKey.py', finalKey]);
                      if (result.stderr
                          .toString()
                          .toLowerCase()
                          .contains('python was not found')) {
                        setState(() {
                          _passkey.text = "";
                        });
                        Navigator.pop(context);
                        CherryToast.error(
                                title: Text(
                                  "Kindly install python and dependencies",
                                  style: TextStyle(
                                      fontSize: Sizing().height(5, 3)),
                                ),
                                autoDismiss: true)
                            .show(context);
                      } else if (result.stderr
                          .toString()
                          .toLowerCase()
                          .contains('traceback (most recent call last)')) {
                        setState(() {
                          _passkey.text = "";
                        });
                        Navigator.pop(context);
                        CherryToast.error(
                                title: Text(
                                  "License key is invalid",
                                  style: TextStyle(
                                      fontSize: Sizing().height(5, 3)),
                                ),
                                autoDismiss: true)
                            .show(context);
                      } else {
                        if (result.stdout != null && result.stdout != '') {
                          String restultOutput = result.stdout;
                          restultOutput = restultOutput.replaceAll('(', " ");
                          restultOutput =
                              restultOutput.replaceAll(')', " ").toString();

                          List<String> resultList = restultOutput.split(',');
                          if (resultList.first != "") {
                            macAddress = resultList.first.replaceAll("'", " ");
                            fromDate =
                                resultList[1].replaceAll("'", " ").trim();
                            toDate =
                                resultList.last.replaceAll("'", " ").trim();
                          }
                          String tillDate = Constants.licenseFormat
                              .format(DateTime.parse(toDate));
                          DateTime now = DateTime.now();
                          String currentDate =
                              Constants.licenseFormat.format(now);
                          if (DateTime.parse(tillDate)
                              .isAfter(DateTime.parse(currentDate))) {
                            //
                            //get mac address
                            var macResult = await Process.run(
                                'python', ['$pythonFilePath/macAddress.py']);
                            if (macResult.stderr.isNotEmpty) {
                              errorLog.add(ErrorLogModel(
                                  errorDescription:
                                      'An error occurred in Python script: ${macResult.stderr}',
                                  duration: DateTime.now().toString()));
                              errorLogService.saveErrorLog(errorLog);
                              print(
                                  'An error occurred in Python script: ${macResult.stderr}');
                            }
                            if (macResult.stdout != null &&
                                macResult.stdout != '') {
                              currentMacAddress = macResult.stdout.toString();
                              if (macAddress.contains('-')) {
                                macAddress = macAddress.replaceAll('-', ':');
                              }

                              //
                              if (macAddress.toLowerCase().trim() ==
                                  currentMacAddress.toLowerCase().trim()) {
                                fromDate = Constants.licenseFormat
                                    .format(DateTime.parse(fromDate));

                                if (DateTime.parse(fromDate) ==
                                        DateTime.parse(currentDate) ||
                                    DateTime.parse(currentDate)
                                        .isAfter(DateTime.parse(fromDate))) {
                                  //Create License file
                                  Directory dir =
                                      await getApplicationSupportDirectory();
                                  String destinationFolder = dir.path;
                                  String fileName = 'cardioData.txt';
                                  File licenseFileold =
                                      File('$destinationFolder\\$fileName');
                                  if (licenseFileold.existsSync()) {
                                    licenseFileold.deleteSync();
                                  }
                                  String destinationPath =
                                      path.join(destinationFolder, fileName);
                                  Directory(destinationFolder)
                                      .createSync(recursive: true);

                                  await File(destinationPath)
                                      .writeAsString(_passkey.text);

                                  Directory dirr =
                                      await Constants.getDataDirectory();
                                  String copyDestinationFolder = dirr.path;
                                  String fileNamee = 'licenseInfo.txt';
                                  String copyDestinationPath =
                                      '$copyDestinationFolder/$fileNamee';
                                  File licenseInfoOld =
                                      File(copyDestinationPath);
                                  if (licenseInfoOld.existsSync()) {
                                    licenseInfoOld.deleteSync();
                                  }

                                  String licenseContent =
                                      '$macAddress,$fromDate,$toDate';
                                  await File(copyDestinationPath)
                                      .writeAsString(licenseContent);
                                  //
                                  HiveHelper().saveLicenseKeyStatus(true);
                                  if (widget.isRenewal) {
                                    HiveHelper().saveLicenseExpired(false);
                                  }
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  CherryToast.success(
                                          title: Text(
                                            "License key is validated",
                                            style: TextStyle(
                                                fontSize:
                                                    Sizing().height(5, 3)),
                                          ),
                                          autoDismiss: true)
                                      .show(context);
                                } else {
                                  Navigator.pop(context);
                                  CherryToast.error(
                                          title: Text(
                                            "License is not activated. Your validity begin on ${fromDate.split('.').first}",
                                            style: TextStyle(
                                                fontSize:
                                                    Sizing().height(5, 3)),
                                          ),
                                          autoDismiss: false)
                                      .show(context);
                                }
                              } else {
                                setState(() {
                                  _passkey.text = "";
                                });
                                Navigator.pop(context);
                                CherryToast.error(
                                        title: Text(
                                          "License key is incorrect",
                                          style: TextStyle(
                                              fontSize: Sizing().height(5, 3)),
                                        ),
                                        autoDismiss: true)
                                    .show(context);
                              }
                            } else {
                              setState(() {
                                _passkey.text = "";
                              });
                              Navigator.pop(context);
                              CherryToast.error(
                                      title: Text(
                                        "Unable to fetch system mac address",
                                        style: TextStyle(
                                            fontSize: Sizing().height(5, 3)),
                                      ),
                                      autoDismiss: true)
                                  .show(context);
                            }
                          } else {
                            Directory dirr = await Constants.getDataDirectory();
                            String copyDestinationFolder = dirr.path;
                            String fileNamee = 'licenseInfo.txt';
                            String copyDestinationPath =
                                '$copyDestinationFolder/$fileNamee';
                            File licenseInfoOld = File(copyDestinationPath);
                            if (licenseInfoOld.existsSync()) {
                              licenseInfoOld.deleteSync();
                            }

                            String licenseContent =
                                '$macAddress,$fromDate,$toDate';
                            await File(copyDestinationPath)
                                .writeAsString(licenseContent);
                            setState(() {
                              _passkey.text = "";
                              HiveHelper().saveLicenseExpired(true);
                            });
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                PageRouter.licenseExpied,
                                (Route<dynamic> route) => false);
                          }
                        } else {
                          setState(() {
                            _passkey.text = "";
                          });
                          Navigator.pop(context);
                          CherryToast.error(
                                  title: Text(
                                    "License key is invalid",
                                    style: TextStyle(
                                        fontSize: Sizing().height(5, 3)),
                                  ),
                                  autoDismiss: true)
                              .show(context);
                        }
                      }
                    } else {
                      setState(() {
                        showErrorMsg = true;
                      });
                    }
                  } on Exception catch (e) {
                    throw e;
                  }
                },
                child: Text(
                  'Verify',
                  style: TextStyle(
                      fontSize: Sizing().height(2, 3), color: whiteColor),
                )))
      ],
    );
  }

  passkeyField() {
    _passkey.selection = TextSelection.collapsed(offset: _passkey.text.length);
    return TextFormField(
      onFieldSubmitted: (val) async {},
      maxLines: null,
      keyboardType: TextInputType.multiline,
      // obscureText: passkeyVisible ? false : true,
      // obscuringCharacter: '*',
      controller: _passkey,
      cursorColor: primaryColor,
      style: TextStyle(fontSize: Sizing().height(2, 4)),
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: primaryColor,
            ),
          ),
          label: Text(
            'Enter passkey',
          ),
          labelStyle: TextStyle(
              color: Colors.grey[700], fontSize: Sizing().height(2, 3))),
      onChanged: (value) async {
        setState(() {
          showErrorMsg = false;
        });
      },
    );
  }
}
