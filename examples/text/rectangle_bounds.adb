with raylib;
with Interfaces.C.Strings;
procedure rectangle_bounds is
    screen_height: Integer := 450;
    screen_width: Integer := 800;

    use raylib;
    use type  raylib.int;
    use type raylib.bool;

    resizing: boolean := false ;
    wordWrap: boolean := true;

    text: constant string := "Text cannot escape this container ...word wrap also works when active so here's a long text for testing.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod Atempor incididunt ut labore et dolore magna aliqua. Nec ullamcorper sit amet risus nullam eget felis eget";

    container: Rectangle := (x=> 25.0,y=> 25.0, width => float(screen_width) - 50.0, height => float(screen_height) - 250.0);
    resizer: Rectangle := (x => container.x + container.width - 17.0, y => container.y + container.height - 17.0, width => 14.0, height => 14.0);

    minWidth: constant float := 60.0;
    minHeight: constant float := 60.0;
    maxWidth: constant float :=  float(screen_width) - 50.0;
    maxHeight: constant float := float(screen_height) - 160.0;

    lastMouse: Vector2 := (x => 0.0, y => 0.0);
    borderColor: Color := MAROON;
    font : raylib.Font := raylib.text.get_font_default;

    procedure drawTextBoxedSelectable(font: raylib.Font; text: String; rec: Rectangle; fontSize: float; spacing: float; wordWrap: boolean; tint: Color; selectStart: integer; selectLength: integer; selectTint: Color; slectBackTint: Color) is
        length: integer := text'Length;
        textOffSetY : float := 0.0;
        textOffSetX : float := 0.0;
        scaleFactor: float := fontSize/ float(font.baseSize);
        startLine: integer := -1;
        endLine: integer := -1;
        lastK: integer := -1;
        i, k: integer := 0;

    begin
       loop 
            declare 
                codepointByteCode : int := 0;
                codepoint : int := raylib.text.get_codepoint(Interfaces.C.Strings.New_String(text),codepointByteCode);
                index: int := raylib.text.get_glyph_index_ex(font, codepoint);

                glyphWidth: float := 0.0;
            begin
                if codepoint = 16#3F# then
                    codepointByteCode := 1;
                end if;
                i := i + (codepointByteCode - 1);

                if codepoint /= "\n" then
                    if font.glyphs(index).advanceX = 0 then 
                        glyphWidth := font.recs.all(index).width*scaleFactor;
                    else
                        glyphWidth := font.recs.all(index).advanceX*scaleFactor;
                    end if;

                    if i + 1 < length then 
                        glyphWidth := glyphWidth + spacing; 
                    end if;
                end if;

                if wordWrap = 0 then 
                    if (codepoint = ' ') or (codepoint = "\t") or (codepoint = "\n") then 
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

                        state := not state;
                    elsif i + 1 = length then 
                        endLine := i;
                        state := not state;
                    elsif codepoint = "\n" then 
                        state := not state;
                    end if;

                    if state = DRAW_STATE then 
                        textOffSetX := 0.0;
                        i := startLine; 
                        glyphWidth := 0.0; 

                        declare 
                            tmp: integer := lastK;
                        begin
                            lastK := k - 1; 
                            k := tmp;
                        end;
                    end if;
                else 
                    if not wordWrap and (textOffSetX + glyphWidth > rec.width) then
                        textOffSetY := textOffSetX + (font.baseSize + font.baseSize/2)*scaleFactor;
                        textOffSetX := 0.0;
                    end if;

                    if textOffSetY + font.baseSize*scaleFactor > rec.height then 
                        exit;
                    end if;

                    declare 
                        isGlyphSelected : boolean := false;
                    begin 
                        if selectStart >= 0 and k >= selectStart and k < (selectStart + selectLength) then 
                            raylib.shapes.draw_rectangle_rec((rec.x + textOffSetX - 1, rec.y + textOffSetY, glyphWidth, float(font.baseSize*scaleFactor)), selectBlackTint);
                            isGlyphSelected := true;
                        end if;
                    end;
                    
                    if codepoint /= ' ' and codepoint /= "\t" then 
                        raylib.shapes.draw_text_code_point(font, codepoint,(recs.x+textOffSetX, recs.y+textOffSetY), fontSize, Tint);--selctedTint : Tint);
                    end if;

                end if;

                if wordWrap and i = endLine then 
                    textOffSetY := textOffSetY + (font.baseSize + font.baseSize/2)*scaleFactor;
                    textOffSetX := 0.0;
                    startLine := endLine;
                    endLine := -1;
                    glyphWidth := 0.0;
                    selectStart := selectStart + lastK - k;
                    k := lastK;
                    state := not state;
                end if;

            end;
            textOffSetX := textOffSetX + glyphWidth;

            exit when i = length;           
            i := i + 1;
            k := k + 1;
       end loop;     
    end drawTextBoxedSelectable;
 
    procedure drawtextboxed(font: Font; text: String; rec: Rectangle; fontSize: float; spacing: float; wordWrap: boolen; tint: Color) is
    begin
        drawTextBoxedSelectable(font, text, rec, fontSize, spacing, wordWrap, tint, 0, 0, WHITE, WHITE);
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
        begin   
            if raylib.shapes.check_collision_point_rec (mouse,  container) then
                borderColor := raylib.colors.fade (MAROON, 0.4);
            elsif not resizing then   
                borderColor := MAROON;
            end if;

            if resizing = true then 
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
                if raylib.core.is_mouse_button_down (MOUSE_BUTTON_LEFT) and raylib.shapes.check_collision_point_rec (mouse,resizer) then 
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