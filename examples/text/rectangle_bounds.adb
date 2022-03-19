with raylib;
with Interfaces.C.Strings;
with Ada.Characters.Latin_1;

procedure rectangle_bounds is

    screen_width: Integer := 800;
    screen_height: Integer := 450;

    use raylib;
    use type  raylib.int;
    use type raylib.bool;

    resizing: boolean := false ;
    wordWrap: boolean := true;

    text: constant string := "Text cannot escape \tthis container\t...word wrap also works when active so here's" &
        " a long text for testing.\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit, sed do" & 
        " eiusmod Atempor incididunt ut labore et dolore magna aliqua. Nec ullamcorper sit amet risus nullam eget felis eget";

    container: Rectangle := (x=> 25.0, y=> 25.0, width => float(screen_width) - 50.0, height => float(screen_height) - 250.0);
    resizer: Rectangle := (x => container.x + container.width - 17.0, y => container.y + container.height - 17.0, width => 14.0, height => 14.0);

    minWidth: constant float := 60.0;
    minHeight: constant float := 60.0;
    maxWidth: constant float :=  float(screen_width) - 50.0;
    maxHeight: constant float := float(screen_height) - 160.0;

    lastMouse: Vector2 := (x => 0.0, y => 0.0);
    borderColor: Color := MAROON;
    font : raylib.Font := raylib.text.get_font_default;

    procedure drawTextBoxedSelectable(font: raylib.Font; text: String; rec: Rectangle; fontSize: float; spacing: float; wordWrap: boolean; tint: Color; selectStart: in out int; selectLength: int; selectTint: Color; selectBackTint: Color) is
        length: integer := text'Length;
        textOffSetY : float := 0.0;
        textOffSetX : float := 0.0;
        scaleFactor: float := fontSize/ float(font.baseSize);

        type State is (DRAW_STATE, MEASURE_STATE);
        
        function next_state(s : in State) return State is 
        begin 
            if s = DRAW_STATE then 
                return MEASURE_STATE;
            else 
                return DRAW_STATE;
            end if;
        end next_state;

        current_state: State := State'Val(Boolean'Pos(wordWrap));
        startLine: int := -1;
        endLine: int := -1;
        lastK: int := -1;
        i, k: int := 0;

    begin
        for n in 1 .. length loop
            declare 
                codepointByteCode : int := 0;
                codepoint : Character := raylib.text.get_codepoint_ex(Interfaces.C.Strings.New_String(text),codepointByteCode);
                index: int := raylib.text.get_glyph_index_ex(font, Interfaces.C.int(Character'Pos(codepoint)));

                glyphWidth: float := 0.0;
            begin
                if Character'Pos(codepoint) = 16#3F# then
                    codepointByteCode := 1;
                end if;

                i := i + (codepointByteCode - 1);

                if codepoint /= Ada.Characters.Latin_1.LF then
                    if font.glyphs.advanceX = 0 then 
                        glyphWidth := font.recs.width*scaleFactor;
                    else
                        glyphWidth := float(font.glyphs.advanceX)*scaleFactor;
                    end if;

                    if i + 1 < int(length) then 
                        glyphWidth := glyphWidth + spacing; 
                    end if;
                end if;

                if current_state = MEASURE_STATE then 
                    if (codepoint = Ada.Characters.Latin_1.Space) or (codepoint = Ada.Characters.Latin_1.HT) or (codepoint = Ada.Characters.Latin_1.LF) then 
                        endLine := i;
                    end if;

                    if textOffSetX + glyphWidth > rec.width then 
                        if endLine < 1 then 
                            endLine := i;
                        else 
                            endLine := endLine;
                        end if;

                        if startLine + codepointByteCode = endLine then 
                            endLine := i - codepointByteCode;

                        end if; 
                        current_state := next_state(current_state);
                    elsif i + 1 = int(length) then 
                        endLine := i;
                        current_state := next_state(current_state);
                    elsif codepoint = Ada.Characters.Latin_1.LF then 
                        current_state := next_state(current_state);
                    end if;

                    if current_state = DRAW_STATE then 
                        textOffSetX := 0.0;
                        i := startLine; 
                        glyphWidth := 0.0; 

                        declare 
                            tmp: int := lastK;
                        begin
                            lastK := k - 1; 
                            k := tmp;
                        end;
                    end if;
                else 
                    if codepoint = Ada.Characters.Latin_1.LF then 
                        if not wordWrap then
                            textOffSetY := textOffSetY + float(font.baseSize + font.baseSize/2)*scaleFactor;
                            textOffSetX := 0.0;
                        end if;

                    else 
                        if not wordWrap and (textOffSetX + glyphWidth > rec.width) then
                            textOffSetY := textOffSetY + float(font.baseSize + font.baseSize/2)*scaleFactor;
                            textOffSetX := 0.0;
                        end if;
                   
                        if textOffSetY + float(font.baseSize)*scaleFactor > rec.height then 
                            exit;
                        end if;

                        declare 
                            isGlyphSelected : boolean := false;
                        begin 
                            if selectStart >= 0 and k >= selectStart and k < (selectStart + selectLength) then 
                                raylib.shapes.draw_rectangle_rec((rec.x + textOffSetX - 1.0, rec.y + textOffSetY, glyphWidth, float(font.baseSize)*scaleFactor), selectBackTint);
                                isGlyphSelected := true;
                            end if;
                        end;
                    
                        if codepoint /= Ada.Characters.Latin_1.Space and codepoint /= ada.Characters.Latin_1.HT then 
                            raylib.text.draw_text_code_point(font, Character'Pos(codepoint),(rec.x+textOffSetX, rec.y+textOffSetY), fontSize, Tint);--selctedTint : Tint);
                        end if;
                    end if;
                end if;
                if wordWrap and i = endLine then 
                    textOffSetY := textOffSetY + float(font.baseSize + font.baseSize/2)*scaleFactor;
                    textOffSetX := 0.0;
                    startLine := endLine;
                    endLine := (-1);
                    glyphWidth := 0.0;
                    selectStart := selectStart + lastK - k;
                    k := lastK;
                    current_state := next_state(current_state);
                end if;
            textOffSetX := textOffSetX + glyphWidth;

            exit when i = int(length);           
            i := i + 1;
            k := k + 1;
        end;
       end loop;     
    end drawTextBoxedSelectable;
 
    procedure drawtextboxed(font: raylib.Font; text: String; rec: Rectangle; fontSize: float; spacing: float; wordWrap: boolean; tint: Color) is
        selectStart: int := 0; 
    begin
        drawTextBoxedSelectable(font, text, rec, fontSize, spacing, wordWrap, tint, selectStart, 0, WHITE, WHITE);
    end drawtextboxed;
begin
    raylib.window.init(
        screen_width,
        screen_height,
        "raylib [text] example - draw text inside a rectangle"
    );

    raylib.set_target_FPS (60);

    while not raylib.window.should_close loop 
        if raylib.core.is_key_pressed (KEY_SPACE) then 
            wordWrap := not wordWrap;
        end if;
        declare 
            mouse: Vector2 := core.get_mouse_position;
            width, height: float;
        begin   
            if raylib.shapes.check_collision_point_rec (mouse,  container) then
                borderColor := raylib.colors.fade (MAROON, 0.4);
            elsif not resizing then   
                borderColor := MAROON;
            end if;

            if resizing then 
                if raylib.core.is_mouse_button_pressed (MOUSE_LEFT_BUTTON) then 
                    resizing := false;
                end if;

                width := container.width + (mouse.x - lastMouse.x);
                if width > maxWidth then
                    if width < maxWidth then 
                        container.width := width;
                    else    
                        container.width := maxWidth;
                    end if;
                else 
                    container.width := minWidth;
                end if;

                height := container.height + (mouse.y - lastMouse.y);
                if height > maxHeight then
                    if height < maxHeight then 
                        container.height := height;
                    else    
                        container.height := maxHeight;
                    end if;
                else 
                    container.height := minHeight;
                end if;
            else 
                if raylib.core.is_mouse_button_down (MOUSE_LEFT_BUTTON) and raylib.shapes.check_collision_point_rec (mouse,resizer) then 
                    resizing := true;
                end if;
            end if;

            resizer.x := container.x + container.width - 17.0;
            resizer.y := container.y + container.height - 17.0;

            lastMouse := mouse;
        end;

        raylib.begin_drawing;
        raylib.clear_background (RAYWHITE);
        raylib.shapes.draw_rectangle_lines_ex (rec => container, line_thick => 3, c => borderColor);

        --drawtextboxed(font, text, rectangle);

        raylib.shapes.draw_rectangle_rec (resizer, borderColor);
        raylib.shapes.draw_rectangle (posX => 0, posY => int(screen_height - 54), width => int(screen_width), height => 54, c => GRAY);
        raylib.shapes.draw_rectangle_rec ((382.0,float(screen_height - 34),12.0,12.0) , MAROON);
        raylib.text.draw ("Word Wrap: ", posX => 313, posY => int(screen_height - 15), fontSize => 20, c => BLACK);
        if wordWrap then
            raylib.text.draw (text => "ON", posX => 447, posY => int(screen_height - 115), fontSize => 20, c => RED);
        else 
            raylib.text.draw (text => "OFF", posX => 447, posY => int(screen_height - 115), fontSize => 20, c => BLACK);
        end if;
        raylib.text.draw (text => "Press [SPACE] to toggle word wrap", posX => 218, posY => int(screen_height - 86), fontSize => 20, c => GRAY);
 
       raylib.text.draw (text => "Click hold & drag the * to resize the container", posX => 155, posY => int(screen_height - 38), fontSize => 20, c => RAYWHITE);
       raylib.end_drawing;

    end loop;
    raylib.window.close;
end rectangle_bounds;