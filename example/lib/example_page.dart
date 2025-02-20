import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:mifare_nfc_classic/mifare_nfc_classic.dart';
import 'package:mifare_nfc_classic_example/utils.dart';

class ExamplePage extends StatefulWidget {
  @override
  _ExamplePageState createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var hasInformation = false;
  var listInformation = [0, 0];
  List<List<String?>> _cardSectorsInfo = [
    ["A", "B", "C", "D"]
  ];
  var _selectedSector = 0;
  var _selectedBlock;
  String? message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Visibility(
                visible: hasInformation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CarouselSlider.builder(
                      itemCount: _cardSectorsInfo.length,
                      options: CarouselOptions(height: 200.0),
                      itemBuilder: (context, index, realIndex) {
                        return Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sector $index'),
                              Text(
                                  '${_cardSectorsInfo[index][0]}\n${_cardSectorsInfo[index][1]}\n${_cardSectorsInfo[index][2]}\n${_cardSectorsInfo[index][3]}'),
                            ],
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Sector'),
                        DropdownButton<int>(
                          hint: Text('Select a Sector'),
                          value: _selectedSector,
                          items: generateSectorList(listInformation[0])
                              .map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedSector = value;
                              _selectedBlock = generateBlockList(
                                  _selectedSector, listInformation[1])[0];
                            });
                          },
                        ),
                        Text('Block'),
                        DropdownButton<int>(
                          hint: Text('Select a Block'),
                          value: _selectedBlock,
                          items: generateBlockList(
                                  _selectedSector, listInformation[1])
                              .map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBlock = value;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 50.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final message = await MifareNfcClassic.readBlock(
                              blockIndex: _selectedBlock,
                            );
                            await showToast(message: message ?? '');
                          },
                          child: Text('Read X Block Of Y Sector'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final message = await MifareNfcClassic.readSector(
                              sectorIndex: _selectedSector,
                              password: this.message,
                            );
                            await showToast(
                                message:
                                    '${message[0]}\n${message[1]}\n${message[2]}\n${message[3]}');
                          },
                          child: Text('Read X Sector'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            _cardSectorsInfo = await MifareNfcClassic.readAll();
                            setState(() {});
                          },
                          child: Text('Read All'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async => showToast(
                              message: (await MifareNfcClassic.blockCount)
                                  .toString()),
                          child: Text('Get Block Count'),
                        ),
                        ElevatedButton(
                          onPressed: () async => showToast(
                              message: (await MifareNfcClassic.sectorCount)
                                  .toString()),
                          child: Text('Get Sector Count'),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      margin: const EdgeInsets.symmetric(vertical: 15.0),
                      child: Form(
                        key: _formKey,
                        child: TextFormField(
                          initialValue: 'af0910ceff69'.toUpperCase(),
                          onSaved: (newValue) => message = newValue,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: 'Message',
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        _formKey.currentState?.save();
                        if (_selectedSector == 0 ||
                            (_selectedBlock + 1) % 4 == 0) {
                          showToast(
                              message: "Don't Write in this sector or block");
                        } else if (message?.isEmpty ?? true) {
                          showToast(message: "Write Something");
                        } else {
                          await MifareNfcClassic.writeBlock(
                              blockIndex: _selectedBlock, message: message);
                        }
                      },
                      child: Text('Write X Block'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        _formKey.currentState?.save();
                        if (message?.isEmpty ?? true) {
                          showToast(message: "Write Something");
                        } else {
                          await MifareNfcClassic.writeRawHexToBlock(
                              blockIndex: _selectedBlock, message: message);
                        }
                      },
                      child: Text('Write X Block (Raw)'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        _formKey.currentState?.save();
                        if (message?.isEmpty ?? true) {
                          showToast(message: "Write Something");
                        } else {
                          await MifareNfcClassic.changePasswordOfSector(
                            sectorIndex: 1,
                            newPassword: message,
                          );
                        }
                      },
                      child: Text('Change Password'),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: !hasInformation,
                child: ElevatedButton(
                  onPressed: () async {
                    listInformation.clear();
                    listInformation.addAll(await buildInitialAlert(context));
                    setState(() {
                      hasInformation = !hasInformation;
                    });
                  },
                  child: Text('Read Card Information'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
