* ALV Objects data def include
data: gr_salv type ref to cl_salv_table.
data: gr_container type ref to cl_gui_custom_container.
class lcl_handle_events definition deferred.
data: gr_events type ref to lcl_handle_events.
Data: gr_selections type ref to cl_salv_selections. 
type-pools : icon. 
constants: c_red    value 1,
           c_yellow value 2,
           c_green  value 3. 
* class include
class lcl_handle_events definition.
  public section.
    methods:
      on_user_command for event added_function of cl_salv_events
        importing e_salv_function,
      on_link_click for event link_click of cl_salv_events_table
        importing row column  .

endclass.
class lcl_handle_events implementation.
  method on_user_command.
    perform  user_command using e_salv_function .
  endmethod.                    "on_user_command
  method on_link_click.
    read table gt_out into gt_out index row.
    if sy-subrc = 0.
      set  :parameter id 'VF' field gt_out-vbeln.
      call transaction 'VF03' and skip first screen.
    endif.
  endmethod.

endclass. 


end-of-selection.
  perform display_data. 

* form include
form display_data .
** Declarations for ALV Functions
  data : gr_functions type ref to cl_salv_functions_list.
** declaration for Layout Settings
  data: gr_layout     type ref to cl_salv_layout,
        gr_layout_key type salv_s_layout_key.
** Declaration for Global Display Settings
  data : gr_display type ref to cl_salv_display_settings.
  data: lv_repid type sy-repid.
  try.

      call method cl_salv_table=>factory
        importing
          r_salv_table = gr_salv
        changing
          t_table      = gt_out[].
      lv_repid = sy-repid.
*
*    gr_salv->set_screen_status(
*    pfstatus      = 'STATUS'
*    report        = lv_repid
*    set_functions = gr_salv->c_functions_all ).
*
*--------------------------------------------------------------------*
*change description of text column
* Get the column object
      data: lr_columns type ref to cl_salv_columns_table,
            lr_column  type ref to cl_salv_column_table,
            ls_color   type lvc_s_colo.

      lr_columns = gr_salv->get_columns( ).
      lr_columns->set_optimize( 'X' ).

      gr_selections = gr_salv->get_selections( ).
      gr_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).


      data: lr_events type ref to cl_salv_events_table.
      lr_events = gr_salv->get_event( ).
      create object gr_events.

*... §6.1 register to the event USER_COMMAND
      set handler gr_events->on_user_command for lr_events.
      set handler gr_events->on_link_click for lr_events.
*--------------------------------------------------------------------*
** Get functions detai
      gr_functions = gr_salv->get_functions( ).
** Activate All Buttons in Tool Bar
      gr_functions->set_all( if_salv_c_bool_sap=>true ).

******* Layout Settings  *******
      move sy-repid to gr_layout_key-report.
      "Set Report ID as Layout Key"

      gr_layout = gr_salv->get_layout( ).
      "Get Layout of Table"
      gr_layout->set_key( gr_layout_key ).
      "Set Report Id to Layout"
      gr_layout->set_save_restriction( if_salv_c_layout=>restrict_none )
      .

      gr_layout->set_default( if_salv_c_bool_sap=>true ).

      gr_display = gr_salv->get_display_settings( ).
      gr_display->set_striped_pattern( if_salv_c_bool_sap=>true ).
      * Alan tıklama
      try.
          lr_column ?= lr_columns->get_column( 'VBELN' ).
        catch cx_salv_not_found.
      endtry.
      try.
          call method lr_column->set_cell_type
            exporting
              value = if_salv_c_cell_type=>hotspot.
          .
        catch cx_salv_data_error .
      endtry.

      lr_columns = gr_salv->get_columns( ).
      lr_columns->set_exception_column( value = 'LIGHTS' ). 


*      gr_display->set_list_header( 'İhale için Teklif Formu' ).
*
*      lr_column ?= lr_columns->get_column( 'KONUTX' ).
*      lr_column->set_long_text( 'Konu Tanımı' ).
*      lr_column->set_short_text( 'Konu' ).
*      lr_column->set_medium_text( 'Konu Tanımı' ).
*
**      alvde gizlenen alan için aşağıdaki kod kullanılır
*
*      lr_column ?= lr_columns->get_column( 'KONUTX' ).
*      lr_column->set_visible( abap_false ).


      gr_salv->display( ).
    catch cx_salv_msg .
    catch cx_salv_not_found.
  endtry.

endform.                    " DISPLAY_DATA

form user_command using i_function type salv_de_function.

  data: lt_rows       type salv_t_row.
  data: l_row         type i.
  data wa_rows  like line of  lt_rows.
  data wa_out  like line of  gt_out.

  gr_selections = gr_salv->get_selections( ).
  lt_rows       = gr_selections->get_selected_rows( ).
  
 case i_function.
    when 'ECAN' or 'ENDE' or 'E'.
      leave to screen 0.
    when 'SEND'.
      perform send_wms.
  endcase.
  gr_salv->refresh( ). 
endform. 
