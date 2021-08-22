import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../globals.dart';
import '../../constants.dart';
import '../../models/track.dart';
import '../../utils/snackBar.dart';
import '../../utils/mapFunctions.dart';
import '../../database/localTracks.dart';
import '../../models/localTrackModel.dart';
import '../../screens/trackDetailsScreen.dart';
import '../../providers/localTracksProvider.dart';

class LocalTrackCard extends StatefulWidget {
  final Track track;
  final int index;

  const LocalTrackCard({@required this.track, @required this.index});

  @override
  _LocalTrackCardState createState() => _LocalTrackCardState();
}

class _LocalTrackCardState extends State<LocalTrackCard> {
  GoogleMapController _googleMapController;
  Set<Polyline> polyLines;

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      printTime: true,
    ),
  );

  @override
  void initState() {
    polyLines = {};
    super.initState();
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: deviceWidth * 0.9,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey[350],
            blurRadius: 3.0,
            spreadRadius: 1.0,
            offset: const Offset(-2, 2),
          ),
        ],
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: kSpringColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(deviceWidth * 0.018), topRight: Radius.circular(deviceWidth * 0.018)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Track ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: kWhiteColor,
                      ),
                      children: [
                        TextSpan(
                          text: widget.track.begin.toUtc().toString().replaceFirst('.000Z', ''),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  child: PopupMenuButton(
                    enabled: true,
                    onSelected: (int menuIndex) {
                      if (menuIndex == 0) {
                        _logger.i('Going to track details screen');
                        Navigator.of(context).pushNamed(
                          TrackDetailsScreen.routeName,
                          arguments: widget.track,
                        );
                      }
                      else if (menuIndex == 1) {
                        final localTracksProvider = Provider.of<LocalTracksProvider>(context, listen: false);
                        localTracksProvider.deleteLocalTrack(widget.track, widget.index);
                        displaySnackBar('Track ${widget.track.id} deleted successfully!');
                      }
                      else if (menuIndex == 2) {
                        final localTracksProvider = Provider.of<LocalTracksProvider>(context, listen: false);
                        localTracksProvider.uploadTrack(context, widget.index);
                      }
                      else if (menuIndex == 3) {
                        final localTracksProvider = Provider.of<LocalTracksProvider>(context, listen: false);
                        localTracksProvider.exportTrack(widget.index);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 0,
                        child: Text(
                          'Show Details',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 1,
                        child: Text(
                          'Delete Track',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 2,
                        child: Text(
                          'Upload Track as Open Data',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 3,
                        child: Text(
                          'Export Track',
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert_outlined,
                      color: kWhiteColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _logger.i('Going to track details screen');
              Navigator.of(context).pushNamed(
                TrackDetailsScreen.routeName,
                arguments: widget.track,
              );
            },
            child: SizedBox(
              height: deviceHeight * 0.2,
              width: double.infinity,
              child: Consumer<LocalTracksProvider>(
                  builder: (context, tracksProvider, child) {
                    final LocalTrackModel trackModel = LocalTracks.getTrackAtIndex(widget.index);
                    LatLng startPosition, destinationPosition;

                    startPosition = LatLng(
                        trackModel.getProperties.values.first.latitude,
                        trackModel.getProperties.values.first.longitude
                    );

                    destinationPosition = LatLng(
                        trackModel.getProperties.values.last.latitude,
                        trackModel.getProperties.values.last.longitude
                    );

                    return GoogleMap(
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      initialCameraPosition: getInitialCameraPosition(
                          startPosition.latitude,
                          startPosition.longitude
                      ),
                      circles: getCircles(startPosition, destinationPosition),
                      polylines: polyLines,
                      onMapCreated: (GoogleMapController googleMapController) async {
                        _googleMapController = googleMapController;
                        animateCamera(startPosition, destinationPosition);
                        polyLines = await setPolyLines(trackModel.properties.values.toList());
                      },
                    );
                  }
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                TrackDetailsScreen.routeName,
                arguments: widget.track,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.track.end
                            .difference(widget.track.begin)
                            .toString()
                            .replaceFirst('.000000', ''),
                        style: const TextStyle(
                          color: kSpringColor,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.track.length.toStringAsFixed(2)}km',
                        style: const TextStyle(
                          color: kSpringColor,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Distance',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void animateCamera(LatLng startLocation, LatLng destinationLocation) {
    if (distanceBetweenCoordinates(startLocation, destinationLocation) > 0.1) {
      setState(() {
        _googleMapController.animateCamera(
            CameraUpdate.newLatLngBounds(getLatLngBounds(
                startLocation,
                destinationLocation
            ), 30));
      });
    }
  }

}
