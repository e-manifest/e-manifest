module ManifestHelper
  def file_upload_button(manifest)
    if manifest.content['uploaded_file'].present?
      link_to 'Download Scanned Image', manifest_manifest_upload_path(manifest_id: @manifest.uuid), class: 'usa-button usa-button-outline'
    else
      'No scanned image available for this manifest.'
    end
  end

  def container_types
    [
      ["BA (Burlap, cloth, paper or plastic bags)", "BA"],
      ["CF (Fiber of plastic boxes, cartons, cases)", "CF"],
      ["CM (Metal boxes, cartons, cases)", "CM"],
      ["CW (Wooden boxes, cartons, cases)", "CW"],
      ["CY (Cylinders)", "CY"],
      ["DF (Fiberbord or plastic drums, barrels, kegs)", "DF"],
      ["DM (Metal drums)", "DM"],
      ["DT (Dump truck)", "DT"],
      ["DW (Wooden drums, barrels, kegs)", "DW"],
      ["HG (Hopper or gondola cars)","HG"],
      ["TC (Tank cars)", "TC"],
      ["TT (Cargo tanks)", "TT"],
      ["TP (Portable tanks)", "TP"]
    ]
  end

  def units_of_measure
    [
      ["Gallons", "G"],
      ["Kilograns", "K"],
      ["Liters", "L"],
      ["Metric tons", "M"],
      ["Cubic Meters", "N"],
      ["Pounds", "P"],
      ["Tons", "T"],
      ["Cubic yards", "Y"]
    ]
  end

  def import_options
    [
      ["Export from U.S.", "export_from_us"],
      ["Import to U.S.", "import_to_us"],
    ]
  end
end