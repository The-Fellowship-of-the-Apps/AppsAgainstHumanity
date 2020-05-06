import 'package:appsagainsthumanity/data/features/game/game_repository.dart';
import 'package:appsagainsthumanity/data/features/game/model/player.dart';
import 'package:appsagainsthumanity/internal.dart';
import 'package:appsagainsthumanity/internal/dynamic_links.dart';
import 'package:appsagainsthumanity/ui/game/bloc/bloc.dart';
import 'package:appsagainsthumanity/ui/widgets/player_circle_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:share/share.dart';

class WaitingRoomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameViewState>(
      bloc: context.bloc<GameBloc>(),
      builder: (context, state) {
        return _buildScaffold(context, state);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, GameViewState state) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        textTheme: context.theme.textTheme,
        iconTheme: context.theme.iconTheme,
        title: Text("Waiting for players"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(72),
          child: Container(
            height: 72,
            padding: const EdgeInsets.only(bottom: 8),
            alignment: Alignment.center,
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Game ID",
                        style: context.theme.textTheme.bodyText1.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        state.game.gid,
                        style: context.theme.textTheme.headline4.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),

                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 16, top: 4),
                        child: OutlineButton(
                          child: Text("INVITE"),
                          color: context.primaryColor,
                          textColor: context.primaryColor,
                          highlightedBorderColor: context.primaryColor,
                          splashColor: context.primaryColor.withOpacity(0.40),
                          borderSide: BorderSide(color: context.primaryColor),
                          onPressed: () async {
                            var link = await DynamicLinks.createLink(state.game.id);
                            await Share.share(link.toString());
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
//        actions: [
//          IconButton(
//            icon: Icon(Icons.group_add),
//            onPressed: () async {
//              var link = await DynamicLinks.createLink(state.game.id);
//              await Share.share(link.toString());
//            },
//          )
//        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: state.isOurGame
          ? FloatingActionButton.extended(
              icon: Icon(MdiIcons.play),
              label: Text("START GAME"),
              backgroundColor: AppColors.primary,
              onPressed: () async {
                context.bloc<GameBloc>()
                    .add(StartGame());
              })
          : null,
      body: BlocListener<GameBloc, GameViewState>(
        bloc: context.bloc<GameBloc>(),
        listener: (context, state) {
          if (state.error != null) {
            Scaffold.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: AppColors.primary,
                ),
              );
          }
        },
        child: _buildPlayerList(context, state),
      ),
    );
  }

  /// Build the player list which is the only component in this particular tree
  /// that needs to update to the change in game state
  Widget _buildPlayerList(BuildContext context, GameViewState state) {
    var players = state.players ?? [];
    var hasRandoBeenInvitedOrNotOwner = (state.players?.any((element) => element.isRandoCardrissian) ?? false) || !state.isOurGame;
    return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: hasRandoBeenInvitedOrNotOwner ? players.length : players.length + 1,
        itemBuilder: (context, index) {
          if (index < players.length) {
            var player = players[index];
            return _buildPlayerTile(context, player, index);
          } else {
            return _buildRandoCardrissianInvite(context, state.game.id);
          }
        });
  }

  Widget _buildPlayerTile(BuildContext context, Player player, int index) {
    var playerName = player.name ?? Player.DEFAULT_NAME;
    if (playerName.trim().isEmpty) {
      playerName = Player.DEFAULT_NAME;
    }
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        onTap: () {},
        title: Text(
          playerName,
          style: context.theme.textTheme.subtitle1.copyWith(color: Colors.white),
        ),
        leading: PlayerCircleAvatar(player: player)
    );
  }

  Widget _buildRandoCardrissianInvite(BuildContext context, String gameDocumentId) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        "Invite Rando Cardrissian?",
        style: context.theme.textTheme.subtitle1.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: CircleAvatar(
        backgroundImage: AssetImage("assets/rando_cardrissian.png"),
      ),
      trailing: Icon(MdiIcons.robot),
      onTap: () async {
        await context.repository<GameRepository>()
            .addRandoCardrissian(gameDocumentId);
      },
    );
  }
}
