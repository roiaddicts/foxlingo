import SwiftUI

struct FootballWordleView: View {
    let pack: GamePack
    @EnvironmentObject private var model: AppModel
    @State private var playerID=""
    @State private var answer=""
    @State private var guesses: [String]=[]
    @State private var input=""
    @State private var feedback=""
    @State private var sessionID=UUID()
    @State private var loaded=false
    @State private var finished=false
    @State private var restart=false
    private var player: GamePlayer? {pack.player(playerID)}
    private var valid: Set<String> {Set(pack.players.flatMap {FootballWordle.names($0)})}
    var body: some View {
        ScrollView {
            VStack(spacing:14) {
                HStack {Text("Find the football name").font(.title3.bold());Spacer();Text("\(guesses.count) / 6").monospacedDigit()}
                Text("Guess a first name, surname or nickname with \(answer.count) letters.").font(.subheadline).foregroundStyle(Palette.muted)
                VStack(spacing:6) {
                    ForEach(0..<6,id:\.self) {row in
                        let text=row < guesses.count ? guesses[row] : row == guesses.count ? input : ""
                        let marks=row < guesses.count ? FootballWordle.feedback(guess:guesses[row],answer:answer) : nil
                        HStack(spacing:5) {
                            ForEach(0..<answer.count,id:\.self) {column in
                                let letters=Array(text)
                                Text(column < letters.count ? String(letters[column]) : " ").font(.system(size:23,weight:.bold,design:.rounded)).frame(maxWidth:.infinity).frame(height:44)
                                    .background(color(marks?[column]),in:RoundedRectangle(cornerRadius:8)).foregroundStyle(marks == nil ? Palette.brand : .white)
                            }
                        }.accessibilityElement(children:.ignore).accessibilityLabel("Guess \(row+1): \(text.isEmpty ? "empty" : text)").accessibilityValue(marks?.map(\.rawValue).joined(separator:", ") ?? "Not submitted").accessibilityIdentifier("wordle-row-\(row)")
                    }
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("wordle-feedback")}
                if finished,let player {
                    EntityArtwork(asset:player.imageAsset,url:player.imageURL,initials:String(player.name.prefix(2)),size:92,isPlayer:true)
                    Text(player.name).font(.title2.bold()).accessibilityIdentifier("wordle-identity")
                    Text(answer).font(.headline.monospaced()).accessibilityIdentifier("wordle-answer")
                    PrimaryButton(title:"Play again",symbol:"arrow.clockwise") {begin()}.accessibilityIdentifier("wordle-replay")
                }
            }.padding(16)
        }.journal().navigationTitle("Football Wordle").navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge:.bottom) {
            if !finished {
                VStack(spacing:6) {
                    ForEach(["QWERTYUIOP","ASDFGHJKL","ZXCVBNM"],id:\.self) {row in
                        HStack(spacing:4) {ForEach(Array(row),id:\.self) {letter in
                            Button {if input.count < answer.count {input.append(letter);model.playSound(.reveal)}} label: {
                                Text(String(letter)).font(.system(size:14,weight:.bold)).frame(maxWidth:.infinity).frame(height:38).background(color(keyMark(letter)),in:RoundedRectangle(cornerRadius:6)).foregroundStyle(keyMark(letter) == nil ? Palette.brand : .white)
                            }.accessibilityIdentifier("wordle-key-\(letter)")
                        }}
                    }
                    HStack {Button("Delete",systemImage:"delete.left") {if !input.isEmpty {input.removeLast()}}.frame(minHeight:38).accessibilityIdentifier("wordle-delete");Spacer();Button("Check name",systemImage:"checkmark") {submit()}.font(.headline).disabled(input.count != answer.count).frame(minHeight:38).accessibilityIdentifier("wordle-submit")}
                }.padding(12).background(.regularMaterial)
            }
        }
        .toolbar {if !finished {Button("Start again",systemImage:"arrow.counterclockwise") {restart=true}.accessibilityIdentifier("wordle-restart")}}
        .alert("Start a new name?",isPresented:$restart) {Button("Start new name",role:.destructive) {begin()};Button("Keep playing",role:.cancel) {}}
        .onAppear {restore()}.onDisappear {persist()}
    }
    private func color(_ mark: LetterMark?) -> Color {
        switch mark {case .correct:Palette.brand;case .present:Palette.ochre;case .absent:Palette.muted;case nil:.white}
    }
    private func keyMark(_ letter: Character) -> LetterMark? {
        var best: LetterMark?
        for guess in guesses {
            let marks=FootballWordle.feedback(guess:guess,answer:answer)!
            for (i,value) in guess.enumerated() where value == letter {
                if marks[i] == .correct {return .correct}
                if marks[i] == .present || best == nil {best=marks[i]}
            }
        }
        return best
    }
    private func submit() {
        guard !finished,input.count == answer.count else {return}
        guard valid.contains(input) else {feedback="Use a football name from the player collection.";return}
        guard !guesses.contains(input) else {feedback="You already tried that name.";return}
        guesses.append(input);let won=input == answer;input="";feedback=""
        if won || guesses.count == 6 {
            finished=true;model.state.removeSavedGame("wordle")
            if won {_ = model.state.completeGame(id:sessionID,kind:"wordle",count:guesses.count,now:model.now);model.respond(true,event:.completion)}
            else {feedback="The name was \(answer). A new name is ready whenever you are.";model.recordGameGap(game:"wordle",context:"Football name · "+(player?.name ?? answer),names:[player?.name ?? answer]);model.respond(false,event:.mismatch)}
            model.save()
        } else {model.playSound(.reveal);persist()}
    }
    private func begin() {
        let eligible=pack.connectionPlayers.filter {!FootballWordle.names($0).isEmpty}
        #if DEBUG
        let selected=ProcessInfo.processInfo.arguments.contains("-ui-testing") ? eligible.first {$0.name == "Lionel Messi"} ?? eligible[0] : eligible.randomElement()!
        #else
        let selected=eligible.randomElement()!
        #endif
        playerID=selected.id
        #if DEBUG
        answer=ProcessInfo.processInfo.arguments.contains("-ui-testing") && FootballWordle.names(selected).contains("MESSI") ? "MESSI" : FootballWordle.names(selected).sorted().randomElement()!
        #else
        answer=FootballWordle.names(selected).sorted().randomElement()!
        #endif
        guesses=[];input="";feedback="";finished=false;sessionID=UUID();persist()
    }
    private func persist() {
        guard loaded,!finished,let player else {return}
        model.state.storeGame(GameResume(signature:FootballWordle.signature(player:player,answer:answer),sessionID:sessionID,wordle:WordleProgress(playerID:playerID,answer:answer,guesses:guesses)),kind:"wordle");model.save()
    }
    private func restore() {
        guard !loaded else {return};loaded=true
        if let resume=model.state.savedGame("wordle"),let progress=FootballWordle.restore(resume,pack:pack,completedSessions:Set(model.state.sessions.map(\.id))) {
            playerID=progress.playerID;answer=progress.answer;guesses=progress.guesses;sessionID=resume.sessionID;return
        }
        begin()
    }
}
